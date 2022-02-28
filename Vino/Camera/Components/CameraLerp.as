
enum ELerpedCameraType
{
	Linear,
	EaseIn,
	EaseOut,
	EaseInOut
}

namespace CameraLerp
{
	float GetAlpha(ELerpedCameraType LerpType, float OriginalAlpha, float Exp = 2.f)
	{
		if(LerpType == ELerpedCameraType::EaseIn)
			return FMath::EaseIn(0.f, 1.f, OriginalAlpha, Exp);
		else if(LerpType == ELerpedCameraType::EaseOut)
			return FMath::EaseOut(0.f, 1.f, OriginalAlpha, Exp);
		else if(LerpType == ELerpedCameraType::EaseInOut)
			return FMath::EaseInOut(0.f, 1.f, OriginalAlpha, Exp);
		else
			return FMath::Lerp(0.f, 1.f, OriginalAlpha);
	}	
}

