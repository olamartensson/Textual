/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
      names of its contributors may be used to endorse or promote products 
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "Encryption.h"
#import "BlowfishBase.h"

@implementation CSFWBlowfish

+ (NSUInteger)estimatedLengthOfStringEncryptedUsing:(CSFWBlowfishEncryptionModeOfOperation)mode thatFitsWithinBounds:(NSInteger)maximumLength;
{
	if (mode == CSFWBlowfishEncryptionNoneModeOfOperation) {
		return maximumLength;
	}

	NSInteger lastEstimatedSize = 0;
	
	for (NSInteger i = 0; i <= maximumLength; i++) {
		NSInteger sizeForLength = 0;
		
		if (mode == CSFWBlowfishEncryptionDefaultModeOfOperation || mode == CSFWBlowfishEncryptionECBModeOfOperation) {
			sizeForLength = [BlowfishBase estimatedLengthForECBEncryptedLength:i];
		} else {
			sizeForLength = [BlowfishBase estimatedLengthForCBCEncryptedLength:i];
		}
		
		if (sizeForLength > maximumLength) {
			break;
		} else {
			lastEstimatedSize = i;
		}
	}
	
	return lastEstimatedSize;
}

+ (NSString *)encodeData:(NSString *)input key:(NSString *)phrase mode:(CSFWBlowfishEncryptionModeOfOperation)mode encoding:(NSStringEncoding)local
{
	if (mode == CSFWBlowfishEncryptionNoneModeOfOperation) {
		return input;
	}
	
	NSString *result = [BlowfishBase encrypt:input key:phrase mode:mode encoding:local];

	if ([result length] <= 0) {
		return nil;
	}

	if (mode == CSFWBlowfishEncryptionCBCModeOfOperation) {
		return [@"+OK *" stringByAppendingString:result];
	} else {
		return [@"+OK " stringByAppendingString:result];
	}
}

+ (NSString *)decodeData:(NSString *)input key:(NSString *)phrase mode:(CSFWBlowfishEncryptionModeOfOperation)mode encoding:(NSStringEncoding)local badBytes:(NSInteger *)badByteCount
{
	if (mode == CSFWBlowfishEncryptionNoneModeOfOperation) {
		return input;
	}

	BOOL hasOKPrefix = [input hasPrefix:@"+OK "];
	BOOL hasMCPSPrefix = [input hasPrefix:@"mcps "];

	if ((hasOKPrefix || hasMCPSPrefix)) {
		if (hasOKPrefix) {
			if ([input length] == 4) {
				return @" "; /* Allow for empty strings. */
			} else {
				input = [input substringFromIndex:4];
			}
		} else if (hasMCPSPrefix) {
			if ([input length] == 5) {
				return @" "; /* Allow for empty strings. */
			} else {
				input = [input substringFromIndex:5];
			}
		}
	} else {
		return nil;
	}
	
	/* Star symbol acts as an auto-on. */
	if ([input hasPrefix:@"*"]) {
		input = [input substringFromIndex:1];
		
		mode = CSFWBlowfishEncryptionCBCModeOfOperation;
	} else {
		mode = CSFWBlowfishEncryptionECBModeOfOperation;
	}
	
	NSString *result = [BlowfishBase decrypt:input key:phrase mode:mode encoding:local badBytes:badByteCount];

	if ([result length] <= 0) {
		return nil;
	}

	return result;
}

@end
