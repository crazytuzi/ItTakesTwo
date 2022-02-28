import Cake.LevelSpecific.Basement.ParentBlob.ButtonHold.ParentBlobButtonHoldWidget;

event void FParentBlobButtonHoldEvent();

class UParentBlobButtonHoldComponent : UActorComponent
{
	bool bButtonHoldActive = false;

	FTransform TargetStandTransform;

	UPROPERTY()
	float CurrentButtonHoldProgress = 0.f;

	UPROPERTY()
	FParentBlobButtonHoldEvent OnButtonHoldCompleted;

	UPROPERTY()
	FParentBlobButtonHoldEvent OnButtonHoldStopped;

	UPROPERTY()
	TSubclassOf<UParentBlobButtonHoldWidget> WidgetClass;

	UPROPERTY()
	UBlendSpace HoldBS;

	USceneComponent AttachComp;

	bool bMayHolding = false;
	bool bCodyHolding = false;

	float MayHoldProgress = 0.f;
	float CodyHoldProgress = 0.f;

	bool bCurrentButtonHoldIsInteraction = false;

	void ButtonHoldStarted(USceneComponent Attach)
	{
		AttachComp = Attach;
		bButtonHoldActive = true;
	}

	void ButtonHoldInteractionStarted(FTransform Transform, USceneComponent Attach)
	{
		AttachComp = Attach;
		bCurrentButtonHoldIsInteraction = true;
		TargetStandTransform = Transform;
		bButtonHoldActive = true;
	}

	void ButtonHoldStopped()
	{
		bButtonHoldActive = false;
		OnButtonHoldStopped.Broadcast();
		OnButtonHoldStopped.Clear();
		OnButtonHoldCompleted.Clear();

		bCurrentButtonHoldIsInteraction = false;
		bMayHolding = false;
		bCodyHolding = false;
		MayHoldProgress = 0.f;
		CodyHoldProgress = 0.f;
	}

	void UpdateCurrentProgress(float Progress)
	{
		CurrentButtonHoldProgress = Progress;
	}

	void ButtonHoldCompleted()
	{
		OnButtonHoldCompleted.Broadcast();
		OnButtonHoldCompleted.Clear();
	}

	void SetPlayerHoldStatus(AHazePlayerCharacter Player, bool bStatus)
	{
		if (Player == Game::GetMay())
		{
			bMayHolding = bStatus;
		}
		else if (Player == Game::GetCody())
		{
			bCodyHolding = bStatus;
		}
	}
}