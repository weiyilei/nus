; ModuleID = 'example1_1.cpp'
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nounwind uwtable
define i32 @main() #0 {
  %1 = alloca i32, align 4
  %w = alloca i32, align 4
  %x = alloca i32, align 4
  %y = alloca i32, align 4
  %z = alloca i32, align 4
  store i32 0, i32* %1
  store i32 0, i32* %z, align 4
  %2 = load i32* %w, align 4
  %3 = icmp slt i32 %2, -10
  br i1 %3, label %4, label %5

; <label>:4                                       ; preds = %0
  store i32 2, i32* %x, align 4
  br label %6

; <label>:5                                       ; preds = %0
  store i32 -4, i32* %x, align 4
  br label %6

; <label>:6                                       ; preds = %5, %4
  %7 = load i32* %x, align 4
  %8 = add nsw i32 %7, 10
  store i32 %8, i32* %x, align 4
  %9 = load i32* %y, align 4
  %10 = icmp ne i32 %9, 10
  br i1 %10, label %11, label %12

; <label>:11                                      ; preds = %6
  store i32 50, i32* %z, align 4
  br label %12

; <label>:12                                      ; preds = %11, %6
  %13 = load i32* %1
  ret i32 %13
}

attributes #0 = { nounwind uwtable "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.ident = !{!0}

!0 = metadata !{metadata !"Ubuntu clang version 3.5.2-3ubuntu1 (tags/RELEASE_352/final) (based on LLVM 3.5.2)"}
