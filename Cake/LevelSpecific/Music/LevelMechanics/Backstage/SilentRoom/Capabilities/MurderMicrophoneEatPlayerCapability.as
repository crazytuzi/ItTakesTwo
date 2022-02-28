import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone;
import Vino.PlayerHealth.PlayerHealthComponent;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;

enum EMurderMicrophoneEatState
{
	Approach,
	Bite,
	Rotate,
	Swallow
}

class UMurderMicrophoneEatPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 20;

	AMurderMicrophone Snake;
	UMurderMicrophoneMovementComponent MoveComp;
	AHazePlayerCharacter Player;
	UMurderMicrophoneSettings Settings;

	FHazeAcceleratedVector AcceleratedTargetLocation;
	FHazeAcceleratedVector AcceleratedTargetFacingDirection;

	FVector StartLocation;
	FVector TargetLocation;

	float Elapsed = 0.0f;

	bool bStartEating = false;
	bool bDoneEatingPlayer = false;
	bool bPlayerKilled = false;

	bool bHasLocallyDeactivated = false;
	bool bSyncedDeactivation = false;

	EMurderMicrophoneEatState EatState = EMurderMicrophoneEatState::Approach;

	private TArray<AActor> AttachedActors;

	FTimerHandle FinalHidePlayerHandle;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snake = Cast<AMurderMicrophone>(Owner);
		MoveComp = UMurderMicrophoneMovementComponent::Get(Owner);
		Settings = UMurderMicrophoneSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Snake.TargetToEat == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(Snake.CurrentState != EMurderMicrophoneHeadState::EatingPlayer)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Snake.ApplySettings(Snake.EatPlayerSettings, this, EHazeSettingsPriority::Override);
		bHasLocallyDeactivated = false;
		bSyncedDeactivation = false;

		EatState = EMurderMicrophoneEatState::Approach;
		StartLocation = Snake.SnakeHeadLocation;
		bStartEating = false;
		Player = Snake.TargetToEat;
		bDoneEatingPlayer = false;
		bPlayerKilled = false;
		Elapsed = 0.0f;

		FHazePlaySlotAnimationParams Params;
		Params.Animation = Snake.BiteAnim;
		Snake.HeadMesh.PlaySlotAnimation(Params);
		Snake.AddEyeColor(Snake.AggressiveEyeColor, this, 10);
		UMurderMicrophonePlayerComponent MurderPlayerComp = UMurderMicrophonePlayerComponent::GetOrCreate(Player);
		MurderPlayerComp.bIsEatenBySnake = true;
		Player.MovementComponent.StartIgnoringComponent(Snake.HeadMesh);
		Player.OtherPlayer.DisableOutlineByInstigator(this);

		if (Player.IsMay())
			PauseFoghornActor(Player);
		else if (Player.IsCody())
			PauseFoghornActor(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bHasLocallyDeactivated)
			UpdateEatingStates(DeltaTime);

		if(!bHasLocallyDeactivated && ShouldExit())
		{
			LocalDeactivate();
		}

		FMurderMicrophoneMovementInfo MovementInfo;
		MoveComp.Move(DeltaTime, MovementInfo);

		MoveComp.UpdateFacingRotation(DeltaTime);
		Snake.HeadOffset.SetWorldRotation(MoveComp.FacingRotationCurrent);
		if(EatState != EMurderMicrophoneEatState::Approach)
			Snake.HeadOffset.SetWorldLocation(MovementInfo.FinalLocation);

		Snake.UpdateSpline(DeltaTime);

		if(HasControl())
			Snake.ReplicatedLocation.SetValue(MovementInfo.FinalLocation);
	}

	private void UpdateEatingStates(float DeltaTime)
	{
		if(EatState == EMurderMicrophoneEatState::Approach)
		{
			Elapsed = FMath::Min(Elapsed + DeltaTime, Settings.TimeUntilEatPlayer);
			const FVector DirectionToTarget = (Snake.TargetToEat.ActorCenterLocation - StartLocation).GetSafeNormal();
			const FVector DistanceToTarget = Snake.TargetToEat.ActorCenterLocation - StartLocation;
			const float DistanceFraction = Elapsed / Settings.TimeUntilEatPlayer;
			const FVector NewLocation = StartLocation + DirectionToTarget * (DistanceToTarget.Size() * DistanceFraction);
			MoveComp.SetTargetFacingDirection(DirectionToTarget);
			Snake.HeadOffset.SetWorldLocation(NewLocation);
			//MoveComp.SetTargetLocation(Player.ActorCenterLocation);

			FHazeIntersectionSphere Sphere;
			Sphere.Origin = Snake.SnakeHeadCenterLocation;
			Sphere.Radius = 128.0f;

			FHazeIntersectionCapsule Capsule;
			Capsule.MakeUsingOrigin(Player.CapsuleComponent.WorldLocation, FRotator::ZeroRotator, Player.CapsuleComponent.CapsuleHalfHeight, Player.CapsuleComponent.CapsuleRadius);

			FHazeIntersectionResult Intersection;
			Intersection.QueryCapsuleSphere(Capsule, Sphere);
			//System::DrawDebugSphere(Sphere.Origin, Sphere.Radius, 12, FLinearColor::Red);

			if(Elapsed >= (Settings.TimeUntilEatPlayer * 0.5f) || Intersection.bIntersecting)
			{
				MoveComp.SetTargetLocation(Snake.HeadOffset.WorldLocation);
				MoveComp.SetTargetFacingDirection(MoveComp.FacingDirectionCurrent.GetSafeNormal2D());
				StartEatingPlayer();
			}
		}
		else if(EatState == EMurderMicrophoneEatState::Bite)
		{
			Elapsed -= DeltaTime;

			if(Elapsed < 0.0f)
			{
				EatState = EMurderMicrophoneEatState::Rotate;
				Elapsed = 1.25f;
				TargetLocation = Snake.HeadOffset.WorldLocation + FVector(0.0f, 0.0f, 300.0f);
				//MoveComp.SetTargetLocation(TargetLocation);
				AcceleratedTargetLocation.Value = Snake.HeadOffset.WorldLocation;
				AcceleratedTargetFacingDirection.Value = Snake.HeadOffset.ForwardVector;

			}
		}
		else if(EatState == EMurderMicrophoneEatState::Rotate)
		{
			Elapsed -= DeltaTime;
			AcceleratedTargetLocation.AccelerateTo(TargetLocation, 0.85f, DeltaTime);
			
			//Snake.HeadOffset.SetWorldLocation(AcceleratedTargetLocation.Value);

			AcceleratedTargetFacingDirection.AccelerateTo(Snake.HeadOffset.ForwardVector.GetSafeNormal2D(), 1.0f, DeltaTime);
			//Snake.HeadOffset.SetWorldRotation(AcceleratedTargetFacingDirection.Value.Rotation());
			MoveComp.SetTargetFacingDirection(Snake.HeadOffset.ForwardVector.GetSafeNormal2D());

			const float UpDot = Snake.HeadOffset.UpVector.DotProduct(FVector::UpVector);
			if((UpDot > 0.9f && Elapsed < 0.0f) || Elapsed < -5.0f)
			{
				FHazePlaySlotAnimationParams Params;
				Params.Animation = Snake.SwallowAnim;
				Snake.HeadMesh.PlaySlotAnimation(Params);

				Elapsed = 1.7f;
				EatState = EMurderMicrophoneEatState::Swallow;

				System::SetTimer(this, n"Handle_ShowPlayer", 0.3f, false);

				Params.Animation = Player.IsCody() ? Snake.SwallowCodyAnimation : Snake.SwallowMayAnimation;
				Player.PlaySlotAnimation(Params);
			}

		}
		else if(EatState == EMurderMicrophoneEatState::Swallow && !bDoneEatingPlayer)
		{
			Elapsed -= DeltaTime;

			if(Elapsed < 0.0f)
			{
				ExitEatPlayer();
			}
		}
	}

	private void ExitEatPlayer()
	{
		bDoneEatingPlayer = true;
		//Snake.NetExitEatPlayer();
	}

	private void StartEatingPlayer()
	{
		EGodMode GodMode = GetGodMode(Player);

		if(!IsGodMode())
		{
			HidePlayer();
			
			BlockTags();

			Player.ApplyCameraSettings(Snake.KillCamSettings, FHazeCameraBlendSettings(3.0f), this, EHazeCameraPriority::Script);
			Player.BlockMovementSyncronization(this);
			Player.CleanupCurrentMovementTrail(true);
			Player.AttachToComponent(Snake.HeadMesh, n"Root", EAttachmentRule::SnapToTarget);
			bStartEating = true;

			EatState = EMurderMicrophoneEatState::Bite;
			Elapsed = 1.0f;
			bPlayerKilled = true;

			Snake.PlayOnEatenBark(Player);
		}
		else
		{
			ExitEatPlayer();
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bSyncedDeactivation)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	// Runs what should be run OnDeactivate, and sets a full sync point, which will deactivate this for real.
	private void LocalDeactivate()
	{
		bHasLocallyDeactivated = true;
		Sync::FullSyncPoint(this, n"FinishLocalDeactivation");
	}

	UFUNCTION()
	private void FinishLocalDeactivation()
	{
		bSyncedDeactivation = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Snake.ClearSettingsByInstigator(this);
		MoveComp.ResetRotationVelocity();
		UnblockTags();
		Player.ClearCameraSettingsByInstigator(this);
		
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Player.UnblockMovementSyncronization(this);

		if(Player.HasControl())
		{
			TSubclassOf<UPlayerDeathEffect> EmptyDeathEffect = Snake.DeathEffect;
			if(!IsGodMode())
			{
				KillPlayer(Player, EmptyDeathEffect);
				
			}
		}

		Snake.bSwallowPlayer = true;
		Snake.Local_SetState(EMurderMicrophoneHeadState::Retreat);

		Snake.TargetToEat = nullptr;
		Snake.MovementVelocity = 0.0f;
		
		Snake.RemoveEyeColor(this);

		UMurderMicrophonePlayerComponent MurderPlayerComp = UMurderMicrophonePlayerComponent::GetOrCreate(Player);
		MurderPlayerComp.bIsEatenBySnake = false;
		Player.MovementComponent.StopIgnoringComponent(Snake.HeadMesh);
		Player.OtherPlayer.EnableOutlineByInstigator(this);
		System::ClearAndInvalidateTimerHandle(FinalHidePlayerHandle);
	}

	bool IsGodMode() const
	{
		return GetGodMode(Player) != EGodMode::Mortal;
	}

	UFUNCTION()
	private void Handle_HidePlayer()
	{
		HidePlayer();
	}

	bool ShouldExit() const
	{
		return bDoneEatingPlayer;
	}

	UFUNCTION()
	private void Handle_EatPlayerComplete()
	{
		//bDoneEatingPlayer = true;
	}

	private void HidePlayer()
	{
		Player.SetActorHiddenInGame(true);

		if(Player.IsCody())
			Local_SetCymbalVisible(false);
	}

	UFUNCTION()
	private void Handle_ShowPlayer()
	{
		Player.SetActorHiddenInGame(false);
		if(Player.IsCody())
			Local_SetCymbalVisible(true);

		
		// Ugh, at this point the snake has thrown the player upwards and is about to swallow. We need to hide the player again, otherwise it will appear TPOSED attached at the root of the snake.
		FinalHidePlayerHandle = System::SetTimer(this, n"Handle_HidePlayer", 0.8f, false);
		Player.RootComponent.RelativeLocation = FVector::ZeroVector;
		Player.RootComponent.RelativeRotation = FRotator::ZeroRotator;
	}

	bool bTagsBlocked = false;

	private void BlockTags()
	{
		if(bTagsBlocked)
			return;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(ActionNames::WeaponAim, this);
		Player.BlockCapabilities(n"SongOfLife", this);
		Player.BlockCapabilities(n"Cymbal", this);
		bTagsBlocked = true;
	}

	private void UnblockTags()
	{
		if(!bTagsBlocked)
			return;

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(ActionNames::WeaponAim, this);
		Player.UnblockCapabilities(n"SongOfLife", this);
		Player.UnblockCapabilities(n"Cymbal", this);
		bTagsBlocked = false;
	}
}
