//
//  MSDebugButton.h
//  MSDebug
//
//  Created by moses on 2020/7/6.
//  Copyright © 2020 moses. All rights reserved.
//

#ifdef DEBUG

#import <UIKit/UIKit.h>

@interface MSDebugButton : UIView

@property (nonatomic, strong, readonly) UIButton *button;
@property (nonatomic, assign) BOOL showBorder; /**< 显示边框 */
@property (nonatomic, assign) BOOL showRuler; /**< 显示标尺 */
@property (nonatomic, assign) BOOL showMagnifier; /**< 显示放大镜 */
@property (nonatomic, assign) BOOL showProbeViewInfo; /**< 显示探测View信息 */

@end

#endif
