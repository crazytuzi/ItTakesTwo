import Cake.LevelSpecific.Basement.ParentBlob.Shooting.ParentBlobShootingTargetComponent;

struct FParentBlobKineticInteractionCompletedDelegateData
{
	UPROPERTY(BlueprintReadOnly)
	UParentBlobKineticInteractionComponent Interaction;

}
event void FParentBlobKineticInteractionCompletedSignature(FParentBlobKineticInteractionCompletedDelegateData Data);


class UParentBlobKineticTeam : UHazeAITeam
{
	
}

enum EParentBlobKineticInteractionStatus
{
	CanBeActivated,
	ActivationOutOfReach,
	OutOfReach
}

enum EParentBlobInteractionIconVisibility
{
	Default,
	NoIcon,
	HideWhenInteractingWith,
	HidePermanentWhenInteractingWith
}

enum EParentBlobInputValueChangeType
{
	AcceleratTo,
	SpringTo,
	LerpTo,
	ConstantSpeedTo
}

class UParentBlobKineticInteractionComponent : USceneComponent
{
	UPROPERTY(Category = "Activation")
	bool bBeginAsValidInteraction = true;

	UPROPERTY(Category = "Activation")
	bool bUseVisibilityDistance = true;

	UPROPERTY(Category = "Activation", meta = (EditCondition = "bUseVisibilityDistance"))
	float VisibilityDistance = 3000;

	UPROPERTY(Category = "Activation")
	float ActivationDistance = 1000;

	UPROPERTY(Category = "Activation", meta = (MakeEditWidget))
	FTransform MayFocusShapeTransform;

	UPROPERTY(Category = "Activation", meta = (MakeEditWidget))
	FTransform CodyFocusShapeTransform;

	UPROPERTY(Category = "Progress")
	EParentBlobInputValueChangeType ProgressType = EParentBlobInputValueChangeType::ConstantSpeedTo;

	UPROPERTY(Category = "Progress")
	float ProgressSpeed = 0.4f;

	UPROPERTY(Category = "Progress")
	EParentBlobInputValueChangeType DecayType = EParentBlobInputValueChangeType::ConstantSpeedTo;

	UPROPERTY(Category = "Progress")
	float DecaySpeed = 1.f;

	UPROPERTY(Category = "Progress")
	EParentBlobInteractionIconVisibility IconVisibility = EParentBlobInteractionIconVisibility::Default;

	UPROPERTY(Category = "Completion")
	bool bAllowCompletion = true;

	UPROPERTY(Category = "Events")
	FParentBlobKineticInteractionCompletedSignature OnCompleted;

	UPROPERTY(BlueprintReadOnly, EditConst, Transient, Category = "Completion")
	bool bHasBeenCompleted = false;
	
	private bool bIsAddedToTeam = false;
	private UParentBlobKineticTeam MyTeam;

	FHazeAcceleratedFloat MayHoldProgress;
	FHazeAcceleratedFloat LastMayHoldProgress;
	FHazeAcceleratedFloat CodyHoldProgress;
	FHazeAcceleratedFloat LastCodyHoldProgress;

	bool bLockedByCompletion = false;
	bool bHasBeenInteractedWith = false;
	bool bMayHasInteractedWithThisFrame = false;
	bool bCodyHasInteractedWithThisFrame = false;

	float LastProgressValue = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto HazeOwner = Cast<AHazeActor>(Owner);
		if(HazeOwner != nullptr)
			MakeAvailableAsTarget(bBeginAsValidInteraction);	
		else
			devEnsure(false, "ParentBlobKineticInteractionComponent is attached to " + Owner.GetName() + " which it not a hazeactor");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		MakeAvailableAsTarget(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!bHasBeenCompleted)
		{
			if(bMayHasInteractedWithThisFrame)
				bMayHasInteractedWithThisFrame = false;
			else
				UpdateProgressValue(false, DeltaTime, MayHoldProgress, LastMayHoldProgress);

			if(bCodyHasInteractedWithThisFrame)
				bCodyHasInteractedWithThisFrame = false;
			else
				UpdateProgressValue(false, DeltaTime, CodyHoldProgress, LastCodyHoldProgress);
			
			const float ProgressValue = GetCurrentProgress();
			if(LastProgressValue != ProgressValue)
			{
				OnInteractionUpdated(MayHoldProgress.Value, CodyHoldProgress.Value, ProgressValue);
				LastProgressValue = ProgressValue;
			}

			if(bAllowCompletion && ProgressValue >= 1.f - KINDA_SMALL_NUMBER)
			{
				OnInteractionCompleted();
				MakeAvailableAsTarget(false);
				bHasBeenCompleted = true;
				NetLockUntilCompleted();
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetLockUntilCompleted()
	{
		bLockedByCompletion = true;
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentProgress() const
	{
		return (MayHoldProgress.Value + CodyHoldProgress.Value) * 0.5f;
	}

	UFUNCTION()
	void MakeAvailableAsTarget(bool bStatus)
	{
		if(bIsAddedToTeam == bStatus)
			return;

		if(bHasBeenCompleted)
			return;

		bIsAddedToTeam = bStatus;

		auto HazeOwner = Cast<AHazeActor>(Owner);
		if(bIsAddedToTeam)
		{
			MyTeam = Cast<UParentBlobKineticTeam>(HazeOwner.JoinTeam(n"BlobKinetic", UParentBlobKineticTeam::StaticClass()));
		}
		else
		{
			HazeOwner.LeaveTeam(n"BlobKinetic");
			MyTeam = nullptr;
		}
	}

	void UpdateProgress(float DeltaTime, bool bMayIsHolding, bool bCodyIsHolding)
	{
		if(!bHasBeenInteractedWith)
			bHasBeenInteractedWith = bMayIsHolding || bCodyIsHolding;

		if(bMayIsHolding)
		{
			bMayHasInteractedWithThisFrame = true;
			UpdateProgressValue(true, DeltaTime, MayHoldProgress, LastMayHoldProgress);
		}

		if(bCodyIsHolding)
		{
			bCodyHasInteractedWithThisFrame = true;
			UpdateProgressValue(true, DeltaTime, CodyHoldProgress, LastCodyHoldProgress);
		}
	}

	void UpdateProgressValue(bool bPlayerIsHolding, float DeltaTime, FHazeAcceleratedFloat& Value, FHazeAcceleratedFloat& LastValue)
	{
		LastValue = Value;
		if(!bLockedByCompletion)
		{
			if (bPlayerIsHolding)
			{
				if(ProgressType == EParentBlobInputValueChangeType::ConstantSpeedTo)
					Value.SnapTo(FMath::FInterpConstantTo(Value.Value, 1.f, DeltaTime, ProgressSpeed));
				else if(ProgressType == EParentBlobInputValueChangeType::LerpTo)
					Value.SnapTo(FMath::FInterpTo(Value.Value, 1.f, DeltaTime, ProgressSpeed));
				else if(ProgressType == EParentBlobInputValueChangeType::AcceleratTo)
					Value.AccelerateTo(1.f, ProgressSpeed, DeltaTime);
				else if(ProgressType == EParentBlobInputValueChangeType::AcceleratTo)
					Value.SpringTo(1.f, 10, 10, DeltaTime * ProgressSpeed);		
			}
			else
			{
				if(ProgressType == EParentBlobInputValueChangeType::ConstantSpeedTo)
					Value.SnapTo(FMath::FInterpConstantTo(Value.Value, 0.f, DeltaTime, DecaySpeed));
				else if(ProgressType == EParentBlobInputValueChangeType::LerpTo)
					Value.SnapTo(FMath::FInterpTo(Value.Value, 0.f, DeltaTime, DecaySpeed));
				else if(ProgressType == EParentBlobInputValueChangeType::AcceleratTo)
					Value.AccelerateTo(0.f, DecaySpeed, DeltaTime);
				else if(ProgressType == EParentBlobInputValueChangeType::AcceleratTo)
					Value.SpringTo(0.f, 10, 10, DeltaTime * DecaySpeed);	
			}
		}
		// One side has completed the interaction so we force update the otherside
		else
		{
			Value.SnapTo(FMath::FInterpConstantTo(Value.Value, 1.f, DeltaTime, 20.f));
		}
	}

	bool PlayerIsInteracting(AHazePlayerCharacter Player) const
	{
		if(Player.IsMay())
		{
			if(MayHoldProgress.Value >= 1.f - 0.01f || MayHoldProgress.Value > LastMayHoldProgress.Value)
				return true;
		}
		else
		{
			if(CodyHoldProgress.Value >= 1.f - 0.01f || CodyHoldProgress.Value > LastCodyHoldProgress.Value)
				return true;
		}

		return false;
	}

	bool AnyoneIsInteracting() const
	{
		if(MayHoldProgress.Value >= 1.f - 0.01f || MayHoldProgress.Value > LastMayHoldProgress.Value)
			return true;
		else if(CodyHoldProgress.Value >= 1.f - 0.01f || CodyHoldProgress.Value > LastCodyHoldProgress.Value)
			return true;
		else
			return false;
	}

	void OnInteractionUpdated(float MayProgress, float CodyProgress, float TotalHoldProgress)
	{
		BP_OnInteractionUpdated(MayProgress, CodyProgress, TotalHoldProgress);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnInteractionUpdated(float MayProgress, float CodyProgress, float TotalHoldProgress){}

	protected void OnInteractionCompleted()
	{
		BP_OnInteractionCompleted();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnInteractionCompleted()
	{
		FParentBlobKineticInteractionCompletedDelegateData Data;
		Data.Interaction = this;
		OnCompleted.Broadcast(Data);
	}

	UFUNCTION(BlueprintPure)
	bool GetAvailableTargets(TArray<UParentBlobShootingTargetComponent>& OutTargets) const
	{
		GetAllShootAtTargets(OutTargets);
		return OutTargets.Num() > 0;
	}

	FTransform GetInteractionTransform(EHazePlayer ForPlayer) const
	{
		FTransform InteractionTransform;
		if(ForPlayer == EHazePlayer::Cody)
		{
			InteractionTransform = FTransform(
				WorldTransform.TransformRotation(CodyFocusShapeTransform.Rotation)
				, WorldTransform.TransformPosition(CodyFocusShapeTransform.Location));
		}
		else
		{
			InteractionTransform = FTransform(
				WorldTransform.TransformRotation(MayFocusShapeTransform.Rotation)
				, WorldTransform.TransformPosition(MayFocusShapeTransform.Location));
		}
		return InteractionTransform;
	}

	FVector GetRequiredInputDirection(EHazePlayer ForPlayer) const
	{
		return GetInteractionTransform(ForPlayer).Rotation.ForwardVector;
	}
}


#if EDITOR
class UParentBlobKineticVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UParentBlobKineticInteractionComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		auto Comp = Cast<UParentBlobKineticInteractionComponent>(Component);
        if (Comp == nullptr)
            return;

		if(Comp.bUseVisibilityDistance)
			DrawWireSphere(Comp.GetWorldLocation(), Comp.VisibilityDistance, FLinearColor::Yellow, 10.0f, 12);

		DrawWireSphere(Comp.GetWorldLocation(), Comp.ActivationDistance, FLinearColor::Green, 10.0f, 12);

		// CODY
		{
			FTransform CodyDebugTransform = Comp.GetInteractionTransform(EHazePlayer::Cody);
			FVector DebugFrom = CodyDebugTransform.GetLocation();
			FVector DebugTo = DebugFrom + (Comp.GetRequiredInputDirection(EHazePlayer::Cody) * 800.f);
			DrawArrow(DebugFrom, DebugTo, FLinearColor::Green, 25.f, 3.f);
		}

		// MAY
		{
			FTransform MayDebugTransform = Comp.GetInteractionTransform(EHazePlayer::May);
			FVector DebugFrom = MayDebugTransform.GetLocation();
			FVector DebugTo = DebugFrom + (Comp.GetRequiredInputDirection(EHazePlayer::May) * 750.f);
			DrawArrow(DebugFrom, DebugTo, FLinearColor::Blue, 25.f, 3.f);
		}
    }   
}

#endif // EDITOR