import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

event void FWeightBasedGroundPoundButtonEvent();

class AWeightBasedGroundPoundButton : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Button;

    UPROPERTY(DefaultComponent)
    UGroundPoundedCallbackComponent GroundPoundComp;

    UPROPERTY()
    FHazeTimeLike MoveButtonDownAndStayTimeLike;
    default MoveButtonDownAndStayTimeLike.Duration = 0.25f;

    UPROPERTY(meta = (InlineEditConditionToggle))
    bool bResetAutomatically = false;

    UPROPERTY(meta = (EditCondition = "bResetAutomatically"))
    float ResetAfterTime = 2.f;

    float TargetOffset;
    float StartOffset;
    float OffsetWhenFullyPushed = -125.f;

    bool bFullyPushed = false;
    bool bMoving = false;
	bool bResetting = false;

	UPROPERTY()
	FWeightBasedGroundPoundButtonEvent OnButtonSuccessStarted;

    UPROPERTY()
    FWeightBasedGroundPoundButtonEvent OnButtonFullyPushed;

	UPROPERTY()
	FWeightBasedGroundPoundButtonEvent OnButtonStandardPushStarted;

	FHazeConstrainedPhysicsValue PhysValue;
	default PhysValue.UpperBound = 0.f;
	default PhysValue.LowerBound = -50.f;
	default PhysValue.LowerBounciness = 0.2f;
	default PhysValue.UpperBounciness = 0.6f;
	default PhysValue.Friction = 4.f;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        GroundPoundComp.OnActorGroundPounded.AddUFunction(this, n"ButtonGroundPounded");

        MoveButtonDownAndStayTimeLike.BindUpdate(this, n"UpdateMoveButtonDownAndStay");
        MoveButtonDownAndStayTimeLike.BindFinished(this, n"FinishMoveButtonDownAndStay");

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeavePlatform");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
    }

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlatform(AHazePlayerCharacter Player, FHitResult Hit)
	{
		PhysValue.AddImpulse(-100.f);
		SetActorTickEnabled(true);
	}

	UFUNCTION(NotBlueprintCallable)
	void LeavePlatform(AHazePlayerCharacter Player)
	{
		PhysValue.AddImpulse(-50.f);
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void ForceFullyPushed()
	{
		bFullyPushed = true;
		Button.SetRelativeLocation(FVector(0.f, 0.f, OffsetWhenFullyPushed));
	}

    UFUNCTION()
    void ButtonGroundPounded(AHazePlayerCharacter Player)
    {
        if (!bMoving && !bFullyPushed)
        {
			UCharacterChangeSizeComponent ChangeSizeComp = UCharacterChangeSizeComponent::Get(Player);
			if (ChangeSizeComp != nullptr)
			{
				if (ChangeSizeComp.CurrentSize == ECharacterSize::Large)
				{
					StartOffset = Button.RelativeLocation.Z;
					TargetOffset = OffsetWhenFullyPushed;
					bFullyPushed = true;
				}
			}

            if (bFullyPushed)
            {
				OnButtonSuccessStarted.Broadcast();
                MoveButtonDownAndStayTimeLike.PlayFromStart();
				BP_SuccessfulPress();
                return;
            }

			PhysValue.AddImpulse(-200.f);

			OnButtonStandardPushStarted.Broadcast();
			BP_FailedPress();
        }
    }

	UFUNCTION(BlueprintEvent)
	void BP_FailedPress()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_SuccessfulPress()
	{}

    UFUNCTION()
    void UpdateMoveButtonDownAndStay(float Value)
    {
        float CurrentOffset = FMath::Lerp(StartOffset, TargetOffset, Value);
        Button.SetRelativeLocation(FVector(0.f, 0.f, CurrentOffset));
    }

    UFUNCTION()
    void FinishMoveButtonDownAndStay()
    {
        bMoving = false;

		if (bResetting)
		{
			bFullyPushed = false;
			bResetting = false;
			SetActorTickEnabled(true);
			return;
		}

        OnButtonFullyPushed.Broadcast();

		if (bResetAutomatically)
		{
			System::SetTimer(this, n"ResetButton", ResetAfterTime, false);
		}
    }

	UFUNCTION(NotBlueprintCallable)
	void ResetButton()
	{
		bResetting = true;
		MoveButtonDownAndStayTimeLike.ReverseFromEnd();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bFullyPushed)
		{
			SetActorTickEnabled(false);
			return;
		}

		PhysValue.SpringTowards(0.f, 50.f);
		PhysValue.Update(DeltaTime);

		Button.SetRelativeLocation(FVector(0.f, 0.f, PhysValue.Value));

		if (FMath::Abs(PhysValue.Value) <= SMALL_NUMBER && FMath::Abs(PhysValue.Velocity) <= KINDA_SMALL_NUMBER)
			SetActorTickEnabled(false);
	}
}