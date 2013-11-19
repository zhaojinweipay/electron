// Copyright (c) 2013 GitHub, Inc. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "common/crash_reporter/crash_reporter_mac.h"

#include "base/memory/singleton.h"
#include "base/strings/sys_string_conversions.h"
#import "vendor/breakpad/src/client/apple/Framework/BreakpadDefines.h"

namespace crash_reporter {

CrashReporterMac::CrashReporterMac()
    : breakpad_(NULL) {
}

CrashReporterMac::~CrashReporterMac() {
  if (breakpad_ != NULL)
    BreakpadRelease(breakpad_);
}

void CrashReporterMac::InitBreakpad(const std::string& product_name,
                                    const std::string& version,
                                    const std::string& company_name,
                                    const std::string& submit_url,
                                    bool auto_submit,
                                    bool skip_system_crash_handler) {
  if (breakpad_ != NULL)
    BreakpadRelease(breakpad_);

  std::string display_name = is_browser_ ? product_name :
                                           product_name + " Renderer";

  NSMutableDictionary* parameters =
      [NSMutableDictionary dictionaryWithCapacity:4];

  [parameters setValue:base::SysUTF8ToNSString(product_name)
                forKey:@BREAKPAD_PRODUCT];
  [parameters setValue:base::SysUTF8ToNSString(product_name)
                forKey:@BREAKPAD_PRODUCT_DISPLAY];
  [parameters setValue:base::SysUTF8ToNSString(version)
                forKey:@BREAKPAD_VERSION];
  [parameters setValue:base::SysUTF8ToNSString(company_name)
                forKey:@BREAKPAD_VENDOR];
  [parameters setValue:base::SysUTF8ToNSString(submit_url)
                forKey:@BREAKPAD_URL];
  [parameters setValue:(auto_submit ? @"YES" : @"NO")
                forKey:@BREAKPAD_SKIP_CONFIRM];
  [parameters setValue:(skip_system_crash_handler ? @"YES" : @"NO")
                forKey:@BREAKPAD_SEND_AND_EXIT];

  // Report all crashes (important for testing the crash reporter).
  [parameters setValue:@"0" forKey:@BREAKPAD_REPORT_INTERVAL];

  breakpad_ = BreakpadCreate(parameters);

  for (StringMap::const_iterator iter = upload_parameters_.begin();
       iter != upload_parameters_.end(); ++iter) {
    BreakpadAddUploadParameter(breakpad_,
                               base::SysUTF8ToNSString(iter->first),
                               base::SysUTF8ToNSString(iter->second));
  }
}

void CrashReporterMac::SetUploadParameters() {
  upload_parameters_["platform"] = "darwin";
}

// static
CrashReporterMac* CrashReporterMac::GetInstance() {
  return Singleton<CrashReporterMac>::get();
}

// static
CrashReporter* CrashReporter::GetInstance() {
  return CrashReporterMac::GetInstance();
}

}  // namespace crash_reporter
