import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticBase;


UCLASS(Abstract)
class UParentBlobKineticWidget : UHazeUserWidget
{
	UPROPERTY(NotEditable)
	float MayProgress = 0.f;
	UPROPERTY(NotEditable)
	float CodyProgress = 0.f;

	EParentBlobKineticInteractionStatus CurrentVisibility = EParentBlobKineticInteractionStatus::OutOfReach;
	EParentBlobInteractionIconVisibility IconType = EParentBlobInteractionIconVisibility::Default;
	bool bHasBeenInteractedWith = false;

	void InitalizeKineticWidget(EParentBlobInteractionIconVisibility Type, bool bInteractedWith)
	{
		IconType = Type;
		bHasBeenInteractedWith = bInteractedWith;
	}

	void OnStatusUpdate(float NewMayStatus, float NewCodyStatus)
	{
		MayProgress = NewMayStatus;
		CodyProgress = NewCodyStatus;
		if(MayProgress > KINDA_SMALL_NUMBER || CodyProgress > KINDA_SMALL_NUMBER)
		{
			bHasBeenInteractedWith = true;
			SetVisibilityType(CurrentVisibility);
		}
	}

	void SetVisibilityType(EParentBlobKineticInteractionStatus Type)
	{
		const EParentBlobKineticInteractionStatus LastVisibility = CurrentVisibility;
		CurrentVisibility = Type;

		EParentBlobKineticInteractionStatus FinalVisiblityType = CurrentVisibility;
		const EParentBlobInteractionIconVisibility LastIconType = IconType;
		if(IconType == EParentBlobInteractionIconVisibility::NoIcon)
			FinalVisiblityType = EParentBlobKineticInteractionStatus::OutOfReach;
		else if(IconType == EParentBlobInteractionIconVisibility::HidePermanentWhenInteractingWith && bHasBeenInteractedWith)
			FinalVisiblityType = EParentBlobKineticInteractionStatus::OutOfReach;
		else if(IconType == EParentBlobInteractionIconVisibility::HideWhenInteractingWith && (MayProgress > 0.01f || CodyProgress > 0.01f))
			FinalVisiblityType = EParentBlobKineticInteractionStatus::OutOfReach;

		BP_SetVisibilityType(FinalVisiblityType);
	}

	UFUNCTION(BlueprintEvent)
	void BP_SetVisibilityType(EParentBlobKineticInteractionStatus Type)
	{
	
	}
}