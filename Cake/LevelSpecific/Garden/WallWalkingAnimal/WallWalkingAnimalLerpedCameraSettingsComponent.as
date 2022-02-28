import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Camera.Components.CameraLerp;

struct FLerpedCameraAlignmentData
{
	ELerpedCameraType Type = ELerpedCameraType::Linear;
	float ExpValue = 2.f;
	float Time = 0;
	bool bIntrovertTranslation = false;
}

enum EWallWalkingAnimalActiveCameraType
{
	Normal,
	LaunchPreview,
	Launch,
	Transition,
}

struct FLerpedCameraAlignmentInternalData
{
	EWallWalkingAnimalActiveCameraType TransitionType = EWallWalkingAnimalActiveCameraType::Normal;
	FLerpedCameraAlignmentData LerpData;
	float TimeLeft = 0;
	FVector CameraInitialWorldUp = FVector::ZeroVector;
	FVector OwnerInitialWorldUp = FVector::ZeroVector;
	FRotator LocalIntialRotation = FRotator::ZeroRotator;
	FRotator InitialSpringArmWorldRotation = FRotator::ZeroRotator;
	float InitialPitchDot = 0;
	float InitialRollDot = 0;

	float GetAlpha() const
	{
		if(LerpData.Time <= 0)
			return 1.f;

		const float CurrentAlpha = 1 - (TimeLeft / LerpData.Time);
		return CameraLerp::GetAlpha(LerpData.Type , CurrentAlpha, LerpData.ExpValue);
	}
}

enum ELerpedCameraActiveType
{
	Lerping,
	TargetReached,
	Inactive,
}

class UWallWalkingAnimalLerpedCameraSettingsComponent : UActorComponent
{
	default SetTickGroup(ETickingGroup::TG_LastDemotable);

	private TArray<FLerpedCameraAlignmentInternalData> SettingsStack;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(SettingsStack.Num() > 0)
		{
			FLerpedCameraAlignmentInternalData& ActiveIndex = SettingsStack[SettingsStack.Num() - 1];
			ActiveIndex.TimeLeft = FMath::Max(ActiveIndex.TimeLeft - DeltaTime, 0.f);
		}
	}

	void SetLerpedAlignement(EWallWalkingAnimalActiveCameraType Type, FLerpedCameraAlignmentData Data, UCameraUserComponent CameraUser, UCameraSpringArmComponent SpringArm, FVector CurrentWorldUp)
	{
		SettingsStack.Empty();
		SettingsStack.Add(FLerpedCameraAlignmentInternalData());
		InitializeNewArrayEntry(Type, Data, CameraUser, SpringArm, CurrentWorldUp);
		SetComponentTickEnabled(true);
	}

	void AddLerpedAlignement(EWallWalkingAnimalActiveCameraType Type, FLerpedCameraAlignmentData Data, UCameraUserComponent CameraUser, UCameraSpringArmComponent SpringArm, FVector CurrentWorldUp)
	{
		SettingsStack.Insert(FLerpedCameraAlignmentInternalData(), 0);
		InitializeNewArrayEntry(Type, Data, CameraUser, SpringArm, CurrentWorldUp);
		SetComponentTickEnabled(true);		
	}

	void InitializeNewArrayEntry(EWallWalkingAnimalActiveCameraType Type, FLerpedCameraAlignmentData Data, UCameraUserComponent CameraUser, UCameraSpringArmComponent SpringArm, FVector CurrentWorldUp)
	{
		FLerpedCameraAlignmentInternalData& NewIndex = SettingsStack[0];

		NewIndex.TransitionType = Type;
		NewIndex.LerpData = Data;
		NewIndex.TimeLeft = Data.Time;
		NewIndex.LocalIntialRotation = CameraUser.WorldToLocalRotation(CameraUser.GetDesiredRotation());
		NewIndex.OwnerInitialWorldUp = CurrentWorldUp;
		NewIndex.CameraInitialWorldUp = GetCameraWorldUp(CameraUser);
		NewIndex.InitialSpringArmWorldRotation = SpringArm.PreviousWorldRotation;
		GetPitchRollDot(CameraUser, CameraUser.GetDesiredRotation().UpVector, NewIndex.InitialPitchDot, NewIndex.InitialRollDot);
	}

	float GetLerpAlpha()const
	{
		if(SettingsStack.Num() <= 0)
			return 1.f;
		
		const FLerpedCameraAlignmentInternalData& ActiveIndex = SettingsStack[SettingsStack.Num() - 1];
		return ActiveIndex.GetAlpha();
	}

	FVector GetCameraInitialWorldUp(UCameraUserComponent CameraUser) const
	{
		if(SettingsStack.Num() <= 0)
			return GetCameraWorldUp(CameraUser);

		const FLerpedCameraAlignmentInternalData& ActiveIndex = SettingsStack[SettingsStack.Num() - 1];
		return ActiveIndex.CameraInitialWorldUp;
	}

	FVector GetSpringArmInitialWorldUp(UCameraSpringArmComponent SpringArm) const
	{
		if(SettingsStack.Num() <= 0)
			return SpringArm.PreviousWorldRotation.GetUpVector();

		const FLerpedCameraAlignmentInternalData& ActiveIndex = SettingsStack[SettingsStack.Num() - 1];
		return ActiveIndex.InitialSpringArmWorldRotation.GetUpVector();
	}

	bool GetCurrentLerpedCameraUp(UCameraUserComponent CameraUser, FVector& CurrentWorldUp) const
	{
		if(SettingsStack.Num() <= 0)
			return false;

		const FLerpedCameraAlignmentInternalData& ActiveIndex = SettingsStack[SettingsStack.Num() - 1];
		const float Alpha = ActiveIndex.GetAlpha();

		FVector NewWorldUp = FMath::Lerp(ActiveIndex.CameraInitialWorldUp, CurrentWorldUp, Alpha);
		CurrentWorldUp = NewWorldUp.GetSafeNormal();
		return true;
	}

	FVector GetCameraWorldUp(UCameraUserComponent CameraUser) const
	{
		return CameraUser.GetBaseRotation().GetUpVector();
	}

	// FRotator GetLocalWantedRotationFromWorldRotation(FRotator TargetRotation, UCameraUserComponent CameraUser)const
	// {
	// 	const FRotator LocalTargetRotation = CameraUser.WorldToLocalRotation(TargetRotation);
				
	// 	if(SettingsStack.Num() <= 0)
	// 		return LocalTargetRotation;

	// 	const FLerpedCameraAlignmentInternalData& ActiveIndex = SettingsStack[SettingsStack.Num() - 1];
	// 	const float Alpha = ActiveIndex.GetAlpha();

	// 	return FMath::LerpShortestPath(ActiveIndex.LocalIntialRotation, LocalTargetRotation, Alpha);
	// }

	// FRotator GetLocalWantedRotationFromLocalRotation(FRotator TargetRotation, UCameraUserComponent CameraUser)const
	// {
	// 	if(SettingsStack.Num() <= 0)
	// 		return TargetRotation;

	// 	const FLerpedCameraAlignmentInternalData& ActiveIndex = SettingsStack[SettingsStack.Num() - 1];
	// 	const float Alpha = ActiveIndex.GetAlpha();

	// 	return FMath::LerpShortestPath(ActiveIndex.LocalIntialRotation, TargetRotation, Alpha);
	// }

	FRotator GetLocalInitialRotation(UCameraUserComponent CameraUser) const
	{
		if(SettingsStack.Num() <= 0)
			return CameraUser.WorldToLocalRotation(CameraUser.GetDesiredRotation());

		const FLerpedCameraAlignmentInternalData& ActiveIndex = SettingsStack[SettingsStack.Num() - 1];
		return ActiveIndex.LocalIntialRotation;		
	}

	EWallWalkingAnimalActiveCameraType GetActiveSettingsType(EWallWalkingAnimalActiveCameraType DefaultType)const
	{
		if(SettingsStack.Num() <= 0)
			return DefaultType;

		const FLerpedCameraAlignmentInternalData& ActiveIndex = SettingsStack[SettingsStack.Num() - 1];
		return ActiveIndex.TransitionType;
	}

	bool GetActiveSettingsIsIntrovert(bool bIsByDefault)const
	{
		if(SettingsStack.Num() <= 0)
			return bIsByDefault;

		const FLerpedCameraAlignmentInternalData& ActiveIndex = SettingsStack[SettingsStack.Num() - 1];
		return ActiveIndex.LerpData.bIntrovertTranslation;
	}

	void GetPitchRollDot(UCameraUserComponent CameraUser, FVector WorldUp, float& OutPitchDot, float& OutRollDot)
	{
		const FVector OwnerWorldUp = WorldUp;
		OutPitchDot = WorldUp.DotProduct(OwnerWorldUp);

		const FRotator DesiredRotation = CameraUser.GetDesiredRotation();
		const FRotator RollCompareRotation = Math::MakeRotFromYZ(OwnerWorldUp, WorldUp);
		OutRollDot = DesiredRotation.RightVector.DotProduct(RollCompareRotation.RightVector);
	}

	void GetInitialPitchRollDot(float& OutPitchDot, float& OutRollDot)
	{
		if(SettingsStack.Num() > 0)
		{
			const FLerpedCameraAlignmentInternalData& ActiveIndex = SettingsStack[SettingsStack.Num() - 1];
			OutPitchDot = ActiveIndex.InitialPitchDot;
			OutRollDot = ActiveIndex.InitialRollDot;
		}
	}

	ELerpedCameraActiveType HasActiveLerp() const
	{
		if(SettingsStack.Num() <= 0)
			return ELerpedCameraActiveType::Inactive;
			
		const FLerpedCameraAlignmentInternalData& ActiveIndex = SettingsStack[SettingsStack.Num() - 1];
		const float Alpha = ActiveIndex.GetAlpha();

		if(Alpha >= 1.f)
			return ELerpedCameraActiveType::TargetReached;
		else
			return ELerpedCameraActiveType::Lerping;
	}

	void ConsumeActiveLerpSettings()
	{
		if(SettingsStack.Num() <= 0)
			return;

		SettingsStack.RemoveAt(SettingsStack.Num() - 1);

		if(SettingsStack.Num() <= 0)
		{
			SetComponentTickEnabled(false);
		}
	}

	void ClearAllLerpSettings()
	{
		SettingsStack.Empty();
		SetComponentTickEnabled(false);
	}
}