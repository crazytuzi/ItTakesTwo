import Vino.Interactions.InteractionComponent;
import Vino.Camera.CameraStatics;

import void SetPlayerCannonActor(AHazePlayerCharacter, ACannonToShootMarbleActor) from "Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonToShootMarblePlayerComponent";
import void SetPlayerBeeingShotByCannon(AHazePlayerCharacter, ACannonToShootMarbleActor) from "Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonToShootMarblePlayerComponent";
import Vino.Trajectory.TrajectoryDrawer;

event void FOnPlayerStartedEnterCannon(AHazePlayerCharacter Player);
event void FOnPlayerReleaseCannon(AHazePlayerCharacter Player);
event void FShootCannon(AHazePlayerCharacter PlayerGettingShot);

UCLASS(abstract)
class ACannonToShootMarbleActor : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent YawSyncComp;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent PitchSyncComp;

    UPROPERTY(DefaultComponent, Attach = Root)
    UHazeSkeletalMeshComponentBase SkelMesh;

    UPROPERTY(DefaultComponent, Attach = Base)
	UInteractionComponent JumpInCannonInteraction;

	UPROPERTY(DefaultComponent, Attach = Base)
	UInteractionComponent ShootCannonInteraction;

	UPROPERTY(DefaultComponent)
	UTrajectoryDrawer TrajectoryDrawer;

    UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = "CannonMuzzle")
    USceneComponent FiringAttachPoint;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = "CannonBase")
	UHazeCameraComponent Camera;

    UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = "CannonMuzzle")
    UArrowComponent ShootDirection;

	UPROPERTY(DefaultComponent)
	USceneComponent LeaveCannonTeleportTarget;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY()
	UAnimSequence CodyFireAnimation;

	UPROPERTY()
	UAnimSequence MayFireAnimation;

	UPROPERTY()
	UAnimSequence CannonFire;

	UPROPERTY(DefaultComponent)
	UDummyCannonComponent DummyCannonComp;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = "CannonMuzzle")
	UNiagaraComponent NiagaraComponent;
	default NiagaraComponent.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 8000.f;
	default DisableComponent.bRenderWhileDisabled = true;

	FShootCannon OnShootCannon;
	FShootCannon OnPlayerHitSometing;
	UPROPERTY()
	FOnPlayerStartedEnterCannon OnPlayerStartedEnterCannon;
	UPROPERTY()
	FOnPlayerReleaseCannon OnPlayerReleaseCannon;
	

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ShotFiredEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent JumpInCannonAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent JumpOutCannonAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent PlayMovementAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopMovementAudioEvent;

	UPROPERTY(Category = "Settings|Clamps", meta = (ClampMin = "0", UIMin = "0", ClampMax = "180", UIMax = "180"))
	float ClampLeft = 45.f;

	UPROPERTY(Category = "Settings|Clamps", meta = (ClampMin = "0", UIMin = "0", ClampMax = "180", UIMax = "180"))
	float ClampRight = 45.f;

	UPROPERTY(Category = "Settings|Clamps", meta = (ClampMin = "0", UIMin = "0", ClampMax = "180", UIMax = "180"))
	float ClampDown = 10.f;

	UPROPERTY(Category = "Settings|Clamps", meta = (ClampMin = "0", UIMin = "0", ClampMax = "180", UIMax = "180"))
	float ClampUp = 10.f;

	UPROPERTY(Category = "Settings")
	float YawRate = 20.f;

	UPROPERTY(Category = "Settings")
	float PitchRate = 15.f;

	UPROPERTY(Category = "Settings")
	bool bShowTrajectory = true;

	UPROPERTY(Category = "Settings")
	bool bAllowCancel = true;

	UPROPERTY(NotEditable)
	FRotator RightWheelRot = FRotator(0,0,90);

	UPROPERTY(NotEditable)
	float BarrelPitch = 0;

	UPROPERTY(NotEditable)
	FRotator LeftWheelRot = FRotator(0,0,90);

	UPROPERTY(EditDefaultsOnly)
	UHazeCapabilitySheet PlayerSheet;

    UPROPERTY(Category = "Settings")
	float LaunchForce = 6250.f;

	AHazePlayerCharacter InteractingPlayer;
	// Used for/by the courtyard cannon only
	bool bPlayerReadyToBeShot = false;
	float XAxis;
	float YAxis;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		JumpInCannonInteraction.OnActivated.AddUFunction(this, n"JumpedInCannon");
		ShootCannonInteraction.OnActivated.AddUFunction(this, n"ShootCannon");
		ShootCannonInteraction.DisableForPlayer(Game::GetCody(), n"Interacted");
		ShootCannonInteraction.DisableForPlayer(Game::GetMay(), n"Interacted");

		AddCapability(n"CannonMoveSidewaysCapability");
		AddCapability(n"CannonPitchCapability");
		
		// We prepp the capabilities by adding and removing them so we dont get a spike when we enter the cannon
		{
			Capability::AddPlayerCapabilitySheetRequest(PlayerSheet);
			Capability::RemovePlayerCapabilitySheetRequest(PlayerSheet);
		}
	}

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
	{
		
	}

	UFUNCTION(NotBlueprintCallable)
	protected void JumpedInCannon(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		JumpInCannonInteraction.Disable(n"Interacted");
		InteractingPlayer = Player;
		Capability::AddPlayerCapabilitySheetRequest(PlayerSheet, EHazeCapabilitySheetPriority::Interaction, Player.IsMay() ? EHazeSelectPlayer::May : EHazeSelectPlayer::Cody);
		SetPlayerCannonActor(Player, this);
		StopLookatFocusPoint(Player);
		OnPlayerStartedEnterCannon.Broadcast(Player);
		InteractingPlayer.PlayerHazeAkComp.HazePostEvent(JumpInCannonAudioEvent);
	}

	UFUNCTION()
	void EnableCannonInteraction()
	{
		JumpInCannonInteraction.Enable(n"Interacted");
	}

	void RemoveCapabilityRequest(AHazePlayerCharacter ForPlayer)
	{
		Capability::RemovePlayerCapabilitySheetRequest(PlayerSheet, EHazeCapabilitySheetPriority::Interaction, ForPlayer.IsMay() ? EHazeSelectPlayer::May : EHazeSelectPlayer::Cody);
	}

	void ReleaseCannon()
	{
		OnPlayerReleaseCannon.Broadcast(InteractingPlayer);
		InteractingPlayer.PlayerHazeAkComp.HazePostEvent(JumpOutCannonAudioEvent);
		InteractingPlayer = nullptr;
		System::SetTimer(this, n"EnableCannonInteraction", 1, false);

		if (!ShootCannonInteraction.IsDisabledForAnyReason(EHazePlayerCondition::Cody))
		{
			ShootCannonInteraction.DisableForPlayer(Game::Cody, n"Interacted");
		}
		if (!ShootCannonInteraction.IsDisabledForAnyReason(EHazePlayerCondition::May))
		{
			ShootCannonInteraction.DisableForPlayer(Game::May, n"Interacted");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	protected void ShootCannon(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		// We need to go through the interacting players crumb component since he can decied to leave
		if(InteractingPlayer != nullptr)
		{
			UHazeCrumbComponent::Get(InteractingPlayer).LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_ShootCannon"), FHazeDelegateCrumbParams());

			FHazePlaySlotAnimationParams AnimParams;
			AnimParams.BlendTime = 0.08f;

			if(Player.IsCody())
			{
				AnimParams.Animation = CodyFireAnimation;
			}
			else
			{
				AnimParams.Animation = MayFireAnimation;
			}

			Player.PlaySlotAnimation(AnimParams);
			
			FHazePlaySlotAnimationParams CannonAnimParams;
			CannonAnimParams.Animation = CannonFire;

			SkelMesh.PlaySlotAnimation(CannonAnimParams);
		}	
	}
	
	UFUNCTION(NotBlueprintCallable)
	protected void Crumb_ShootCannon(const FHazeDelegateCrumbData& CrumbData)
	{
		if(InteractingPlayer != nullptr)
		{
			UHazeAkComponent::HazePostEventFireForget(ShotFiredEvent, ActorTransform);
			SetPlayerBeeingShotByCannon(InteractingPlayer, this);
			OnShootCannon.Broadcast(InteractingPlayer);	
			NiagaraComponent.Activate(true);
		}
	}

	UFUNCTION()
	void EnableShootCannon(AHazePlayerCharacter Player)
	{
		FireCannonEffects();
		bPlayerReadyToBeShot = true;
		ShootCannonInteraction.EnableForPlayer(Player, n"Interacted");
	}

	UFUNCTION(BlueprintEvent)
	void FireCannonEffects()
	{
		
	}
}

class UDummyCannonComponent : UActorComponent { }

class UCannonComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UDummyCannonComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UDummyCannonComponent Comp = Cast<UDummyCannonComponent>(Component);
        if (Comp == nullptr)
            return;

		ACannonToShootMarbleActor Cannon = Cast<ACannonToShootMarbleActor>(Comp.Owner);
		if (Cannon == nullptr)
			return;

		FVector CannonBaseLocation = Cannon.SkelMesh.GetSocketLocation(n"CannonBase");
		FRotator CannonBaseRotation = Cannon.SkelMesh.GetSocketRotation(n"CannonBase");
		CannonBaseRotation += FRotator(90.f, 0.f, -180.f);

		// Draw yaw
		DrawArc(Cannon.ActorLocation, Cannon.ClampLeft, 500.f, Cannon.ActorForwardVector.RotateAngleAxis(-Cannon.ClampLeft * 0.5f, Cannon.ActorUpVector), FLinearColor::Blue, Thickness = 4.f, Normal = Cannon.ActorUpVector);
		DrawArc(Cannon.ActorLocation, Cannon.ClampRight, 500.f, Cannon.ActorForwardVector.RotateAngleAxis(Cannon.ClampRight * 0.5f, Cannon.ActorUpVector), FLinearColor::Blue, Thickness = 4.f, Normal = Cannon.ActorUpVector);

		// Draw Pitch
		DrawArc(CannonBaseLocation, Cannon.ClampUp, 500.f, CannonBaseRotation.ForwardVector.RotateAngleAxis(-Cannon.ClampUp * 0.5f, CannonBaseRotation.RightVector), FLinearColor::Blue, Thickness = 4.f, Normal = CannonBaseRotation.RightVector);
		DrawArc(CannonBaseLocation, Cannon.ClampDown, 500.f, CannonBaseRotation.ForwardVector.RotateAngleAxis(Cannon.ClampDown * 0.5f, CannonBaseRotation.RightVector), FLinearColor::Blue, Thickness = 4.f, Normal = CannonBaseRotation.RightVector);
    }
}