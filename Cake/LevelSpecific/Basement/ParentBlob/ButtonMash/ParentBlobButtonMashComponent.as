import Peanuts.ButtonMash.Default.ButtonMashDefault;

event void FParentBlobButtonMashEvent();

class UParentBlobButtonMashComponent : UActorComponent
{
	bool bButtonMashActive = false;

	FTransform TargetStandTransform;

	UPROPERTY()
	float CurrentButtonMashProgress = 0.f;

	UPROPERTY()
	FParentBlobButtonMashEvent OnButtonMashCompleted;

	UPROPERTY()
	FParentBlobButtonMashEvent OnButtonMashStopped;

	bool bMayMashing = false;
	bool bCodyMashing = false;

	float MayMashProgress = 0.f;
	float CodyMashProgress = 0.f;

	UButtonMashDefaultHandle CurrentMayMashHandle;
	UButtonMashDefaultHandle CurrentCodyMashHandle;

	bool bCurrentButtonMashIsInteraction = false;

	void ButtonMashStarted()
	{
		bButtonMashActive = true;
	}

	void ButtonMashInteractionStarted(FTransform Transform)
	{
		bCurrentButtonMashIsInteraction = true;
		TargetStandTransform = Transform;
		bButtonMashActive = true;
	}

	void ButtonMashStopped()
	{
		bButtonMashActive = false;
		OnButtonMashStopped.Broadcast();
		OnButtonMashStopped.Clear();
		OnButtonMashCompleted.Clear();

		bCurrentButtonMashIsInteraction = false;
		bMayMashing = false;
		bCodyMashing = false;
		MayMashProgress = 0.f;
		CodyMashProgress = 0.f;
	}

	void UpdateCurrentProgress(float Progress)
	{
		CurrentButtonMashProgress = Progress;
	}

	void ButtonMashCompleted()
	{
		OnButtonMashCompleted.Broadcast();
		OnButtonMashCompleted.Clear();
	}

	void SetButtonMashHandles(UButtonMashDefaultHandle MayHandle, UButtonMashDefaultHandle CodyHandle)
	{
		CurrentMayMashHandle = MayHandle;
		CurrentCodyMashHandle = CodyHandle;
	}
}