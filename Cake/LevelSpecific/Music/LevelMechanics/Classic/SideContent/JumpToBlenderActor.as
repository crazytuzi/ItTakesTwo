
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundFallCapabilty;

class AJumpToBlenderActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	UStaticMeshComponent Mesh;
	UPROPERTY(DefaultComponent)	
	USceneComponent JumpToLocation;

	UPROPERTY(Category = "Mesh")
    FHazeTimeLike ScaleBouncePadTimeLike;
    default ScaleBouncePadTimeLike.Duration = 0.2f;
    default ScaleBouncePadTimeLike.Curve.ExternalCurve = Asset("/Game/Blueprints/LevelMechanics/BouncePad/BouncePadScaleCurve.BouncePadScaleCurve");
	UPROPERTY(Category = "Mesh")
	float ScalePlayRate = 1.f;
	UPROPERTY(Category = "Mesh")
    FVector EndScale = FVector(1.1f, 1.1f, 0.75f);

	UPROPERTY()
	UForceFeedbackEffect ForceFeedback;

	FVector StartScale = FVector::OneVector;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent JumpToBlenderAudioEvent;
	UPROPERTY(Category = "Bounce Properties")
    float VerticalVelocity = 1750.f;
    UPROPERTY(Category = "Bounce Properties")
    float HorizontalVelocityModifier = 0.5f;

	UPROPERTY()
	bool bShouldDoJumpTo = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedByPlayerDelegate OnPlayerLanded;
        OnPlayerLanded.BindUFunction(this, n"PlayerLandedOnActor");
        BindOnDownImpactedByPlayer(this, OnPlayerLanded);

		ScaleBouncePadTimeLike.BindUpdate(this, n"UpdateScaleBouncePad");
        ScaleBouncePadTimeLike.BindFinished(this, n"FinishScaleBouncePad");
        ScaleBouncePadTimeLike.SetPlayRate(ScalePlayRate);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds){}

	UFUNCTION()
    void UpdateScaleBouncePad(float CurValue)
    {
        FVector CurScale = FMath::Lerp(StartScale, EndScale, CurValue);
        Mesh.SetRelativeScale3D(CurScale);
    }


	UFUNCTION()
    void FinishScaleBouncePad(){}

	UFUNCTION()
	void ChangeBlenderState(bool State)
	{
		bShouldDoJumpTo = State;
	}

	UFUNCTION(NotBlueprintCallable)
    void PlayerLandedOnActor(AHazePlayerCharacter Player, FHitResult HitResult)
    {
		if(Player == Game::GetMay())
		{
			if(!Player.HasControl())
				return;

			bool bGroundPounded = false;
			if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
				bGroundPounded = true;

			Player.PlayForceFeedback(ForceFeedback, false, false, n"BounceRumble");
			Player.SetCapabilityAttributeValue(n"VerticalVelocity", VerticalVelocity);
			Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", HorizontalVelocityModifier);
		//	Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
			ScaleBouncePadTimeLike.PlayFromStart();
							
			if(bShouldDoJumpTo)
			{
				FHazeJumpToData JumpData;
				JumpData.AdditionalHeight = 750;
				JumpData.Transform = JumpToLocation.GetWorldTransform();
				JumpTo::ActivateJumpTo(Game::GetMay(), JumpData);

			}
			else
			{
				Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
			}
		}
		if(Player == Game::GetCody())
		{
			if(!Player.HasControl())
				return;

			bool bGroundPounded = false;
			if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
				bGroundPounded = true;

			Player.PlayForceFeedback(ForceFeedback, false, false, n"BounceRumble");
			Player.SetCapabilityAttributeValue(n"VerticalVelocity", VerticalVelocity);
			Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", HorizontalVelocityModifier);
		//	Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);

			if(bShouldDoJumpTo)
			{
				FHazeJumpToData JumpData;
				JumpData.AdditionalHeight = 750;
				JumpData.Transform = JumpToLocation.GetWorldTransform();
				JumpTo::ActivateJumpTo(Game::GetCody(), JumpData);
				ScaleBouncePadTimeLike.PlayFromStart();
			}
			else
			{
				Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
			}
		}

		Player.PlayerHazeAkComp.HazePostEvent(JumpToBlenderAudioEvent);
    }
}

