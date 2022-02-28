import Vino.Interactions.InteractionComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeaturePlasmaCube;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;

UCLASS(Abstract)
class APushableSpaceBlock : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent RootComp;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UStaticMeshComponent CubeMesh;

	UPROPERTY(DefaultComponent, Attach = CubeMesh)
    UInteractionComponent InteractionPoint;
	default InteractionPoint.MovementSettings.InitializeSmoothTeleport();
	default InteractionPoint.ActionShape.Type = EHazeShapeType::Sphere;
	default InteractionPoint.ActionShape.SphereRadius = 350.f;
	default InteractionPoint.FocusShape.Type = EHazeShapeType::Sphere;
	default InteractionPoint.FocusShape.SphereRadius = 1000.f;
	default InteractionPoint.Visuals.VisualOffset.Location = FVector(0.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent)
	UCharacterChangeSizeCallbackComponent ChangeSizeCallbackComp;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent SyncVectorComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeAkComponent  HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 12000.f;

	UPROPERTY(EditDefaultsOnly)
	USpacestationVOBank VOBank;

	FHazeAudioEventInstance PushingBlockEventInstance;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent CubeStartPushEvent;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent CubeImpactEvent;

	float LastImpactHit = 0.f;

	UPROPERTY(NotVisible)
	float CurrentCodySizeMultiplier = 1.f;

	bool bCodyOnBlock = false;

	FVector LastLocation;

	float LastVelocityDelta;
	float NormalizedVelocityDelta;

	FVector CurrentDirection;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> PushCapability;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ImpactRumble;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeaturePlasmaCube Feature;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence EnterAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence ExitAnim;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	FVector CurrentPlayerInput = FVector::ZeroVector;

	float MoveSpeed = 400.f;

	bool bMayAligned = false;
	bool bBlockingHitActive = false;
	bool bAtBottom = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionPoint.DisableForPlayer(Game::GetCody(), n"Cody");

		CubeMesh.IgnoreActorWhenMoving(Game::GetMay(), true);
		CubeMesh.IgnoreActorWhenMoving(Game::GetCody(), true);
		
		InteractionPoint.OnActivated.AddUFunction(this, n"OnInteractionActivated");

		FActorImpactedByPlayerDelegate ImpactedDelegate;
		ImpactedDelegate.BindUFunction(this, n"OnPlayerLanded");
		BindOnDownImpactedByPlayer(this, ImpactedDelegate);
		
		FActorNoLongerImpactingByPlayerDelegate EndImpactDelegate;
		EndImpactDelegate.BindUFunction(this, n"OnPlayerLeft");
		BindOnDownImpactEndedByPlayer(this, EndImpactDelegate);

		LastVelocityDelta = GetActorLocation().Size();

		Capability::AddPlayerCapabilityRequest(PushCapability.Get(), EHazeSelectPlayer::May);

		InteractionPoint.Disable(n"Alignment");

		SetControlSide(Game::GetMay());
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(PushCapability.Get(), EHazeSelectPlayer::May);
	}

	UFUNCTION()
	void OnPlayerLanded(AHazePlayerCharacter Player, FHitResult Hit)
	{
		if (Player == Game::GetCody())
		{
			bCodyOnBlock = true;
		}
	}

	UFUNCTION()
	void OnPlayerLeft(AHazePlayerCharacter Player)
	{
		if (Player == Game::GetCody())
		{
			bCodyOnBlock = false;
		}
	}

	UFUNCTION()
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		InteractionPoint.Disable(n"Used");
		StartPushing(Player);
    }

    UFUNCTION()
    void StartPushing(AHazePlayerCharacter Player)
    {
        Player.SetCapabilityAttributeObject(n"PushableSpaceBlock", this);
        Player.SetCapabilityActionState(n"PushingSpaceBlock", EHazeActionState::Active);
		
		if(CubeStartPushEvent != nullptr)
		{
			PushingBlockEventInstance = HazeAkComp.HazePostEvent(CubeStartPushEvent);
			HazeAudio::SetPlayerPanning(HazeAkComp, Player);
		}
    }

	void ReleaseBlock()
	{
		InteractionPoint.Enable(n"Used");

		HazeAkComp.HazeStopEvent(PushingBlockEventInstance.PlayingID, bStopAllInstancesOfEvent = true);
		CurrentPlayerInput = FVector::ZeroVector;
	}

    void UpdatePushDirection(FVector PlayerInput)
    {
		if (Game::GetMay().HasControl())
			CurrentPlayerInput = PlayerInput;
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Game::GetMay().HasControl())
		{
			float SizeMultiplier = 0.f;
			if (bCodyOnBlock)
				SizeMultiplier = CurrentCodySizeMultiplier;

			FVector MoveDelta = CurrentPlayerInput * MoveSpeed;
			CurrentDirection = FMath::VInterpTo(CurrentDirection, MoveDelta, DeltaTime, 4.f);
			FVector CodySizeAdder = FVector(0.f, 0.f, -600.f * SizeMultiplier);
			CurrentDirection += CodySizeAdder;

			if (!FMath::IsNearlyEqual(CurrentDirection.Size(), 0.f, 2.f))
			{
				FHitResult Hit;
				CubeMesh.AddWorldOffset(CurrentDirection * DeltaTime, true, Hit, true);

				if (Hit.bBlockingHit)
				{
					if (!bBlockingHitActive)
					{
						bBlockingHitActive = true;
						Game::GetMay().PlayForceFeedback(ImpactRumble, false, true, n"PlasmaCubeImpact");

						if(CubeImpactEvent != nullptr)
						{
							HazeAkComp.SetRTPCValue(HazeAudio::RTPC::MoveObjectImpactForce, FMath::Clamp(FMath::Abs(NormalizedVelocityDelta), 0.f, 1.f), 0.f); 
							HazeAkComp.HazePostEvent(CubeImpactEvent);
						}
					}
					if (Hit.ImpactNormal.Z == 1.f)
						bAtBottom = true;
					else
						bAtBottom = false;
				}
				else
				{
					bBlockingHitActive = false;
					bAtBottom = false;
				}
			}

			SyncVectorComp.SetValue(CubeMesh.WorldLocation);

		}
		else
		{
			CubeMesh.SetWorldLocation(SyncVectorComp.Value);
		}

		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::MoveObjectVelocity, FMath::Clamp(FMath::Abs(NormalizedVelocityDelta), 0.f, 1.f), 0.f);
		UpdateVelocityDeltaRTPC(DeltaTime);

		if (bMayAligned)
		{
			if (!(Game::GetMay().MovementWorldUp - ActorUpVector).IsNearlyZero())
			{
				bMayAligned = false;
				InteractionPoint.Disable(n"Alignment");
			}
		}
		else
		{
			if ((Game::GetMay().MovementWorldUp - ActorUpVector).IsNearlyZero())
			{
				bMayAligned = true;
				InteractionPoint.Enable(n"Alignment");
			}
		}
	}

	UFUNCTION()
	void UpdateVelocityDeltaRTPC(float DeltaTime)
	{
		FVector CurrLocation = CubeMesh.GetWorldLocation();
		FVector VeloVector = (CurrLocation - LastLocation) / DeltaTime;

		NormalizedVelocityDelta = HazeAudio::NormalizeRTPC01(VeloVector.Size(), 0.f, MoveSpeed);		

		LastLocation = CubeMesh.GetWorldLocation();		
	}
}