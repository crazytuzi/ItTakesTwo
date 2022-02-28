import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Jump.AirJumpsComponent;
import Cake.LevelSpecific.Music.MusicJumpTo.MusicJumpToStatics;
import Vino.Movement.MovementSystemTags;

const FName BlockActivationTag = n"MusicGroundPoundBlockTag";
const FName BlockGPTag = n"MusicGroundPoundBlockTag";

class ASpeakerLaunchVolume : AVolume
{
	UPROPERTY()
	float Force;

	UPROPERTY()
	float TimeOn = 0.5f;

	UPROPERTY()
	TArray<AHazeNiagaraActor> OneshotFX;

	UPROPERTY()
	TArray<AHazeNiagaraActor> EnabledFX;

	UPROPERTY()
	bool bIsOn = false;

	UPROPERTY()
	AActor LandPosition;

	UPROPERTY()
	bool bLaunchCody = true;

	UPROPERTY()
	bool bLaunchMay = true;

	bool bShouldHover;

	UPROPERTY()
	float LandpositionAdditionalHeight = 500;

	float CurrentTimeOn = 0;

	TArray<AHazePlayerCharacter> OverlappingPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bIsOn)
		{
			LaunchPlayers();
		}
		else
		{
			DisableAllFX();
		}

		Capability::AddPlayerCapabilityRequest(UCharacterMusicLaunchedGroundPoundBlocker::StaticClass());
	}

	UFUNCTION(BlueprintOverride)
	void EndPLay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(UCharacterMusicLaunchedGroundPoundBlocker::StaticClass());
	}

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
		{
			OverlappingPlayers.Add(Cast<AHazePlayerCharacter>(OtherActor));
		}

		if(bIsOn)
		{
			LaunchPlayers();
		}
		else if(bShouldHover)
		{
			SetPlayersHovering(true);
		}
    }

	UFUNCTION()
	void SetHoverEnabled(bool Hover)
	{
		bShouldHover = Hover;
		SetPlayersHovering(Hover);
	}

	void SetPlayersHovering(bool Hover)
	{
		for (auto player : OverlappingPlayers)
		{
			if (Hover)
			{
				player.SetCapabilityActionState(n"SpeakerHover", EHazeActionState::Active);
			}
			else
			{
				player.SetCapabilityActionState(n"SpeakerHover", EHazeActionState::Inactive);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bIsOn)
		{
			CurrentTimeOn += DeltaTime;

			if (TimeOn == -1)
				return;

			if (CurrentTimeOn > TimeOn)
			{
				bIsOn = false;
				CurrentTimeOn = 0;

				for (auto effect : EnabledFX)
				{
					DisableAllFX();
				}
			}
		}
	}

	UFUNCTION()
	void LaunchPlayers()
	{
		for (AHazeNiagaraActor effect : OneshotFX)
		{
			UNiagaraComponent NiagaraComponent = effect.NiagaraComponent;
			if(NiagaraComponent != nullptr)
			{
				NiagaraComponent.Activate(true);
			}
		}

		for (auto Player : OverlappingPlayers)
		{
			if (Player.IsMay() && bLaunchMay == false ||
				Player.IsCody() && bLaunchCody == false)
				{
					continue;
				}

			Player.SetCapabilityActionState(n"Launchplayer", EHazeActionState::ActiveForOneFrame);

			Player.BlockCapabilities(n"WallSlide", this);
			//Player.BlockCapabilities(MovementSystemTags::GroundPound, BlockGPTag);
			Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementGroundPound);
			Player.SetCapabilityActionState(BlockActivationTag, EHazeActionState::Active);

			FVector Dir;

			if (LandPosition != nullptr)
			{
				FHazeJumpToData JumpData;
				JumpData.Transform = LandPosition.ActorTransform;
				JumpData.AdditionalHeight = LandpositionAdditionalHeight;
				MusicJumpTo::ActivateMusicJumpTo(Player, JumpData);
				SetPlayersHovering(false);

				Dir = LandPosition.ActorLocation - Player.ActorLocation;
				Dir = Math::ConstrainVectorToPlane(Dir, FVector::UpVector);
			}
			else
			{
				SetPlayersHovering(false);
				FVector Upforce = ActorTransform.Rotation.UpVector;
				Upforce *= Force;
				UHazeMovementComponent::Get(Player).Velocity = FVector::ZeroVector;
				Player.AddImpulse(Upforce);
				UCharacterAirJumpsComponent::Get(Player).ConsumeJump();

				Dir = Math::ConstrainVectorToPlane(Upforce, FVector::UpVector);
			}

			Dir.Normalize();
			if (Dir.Size() != 0.f)
			{
				UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
				if (MoveComp != nullptr)
				{
					MoveComp.SetTargetFacingDirection(Dir, 0.1f);
					FHazePointOfInterest PoISettings;
					PoISettings.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
					PoISettings.FocusTarget.WorldOffset = Player.ActorLocation + (Dir * 50000.f) - FVector(0.f, 0.f, 5000.f);
					PoISettings.Duration = 0.75f;
					PoISettings.Blend.BlendTime = 0.75f;
					Player.ApplyPointOfInterest(PoISettings, this);
				}
			}

			Player.UnblockCapabilities(n"WallSlide", this);
		}
		OverlappingPlayers.Empty();
		if(CurrentTimeOn == 0 || CurrentTimeOn == -1)
		{
			bIsOn = true;
			EnableAllFX();
		}
	}

	void EnableAllFX()
	{
		for (auto effect : EnabledFX)
		{
			UNiagaraComponent::Get(effect).Activate();
		}
	}

	void DisableAllFX()
	{
		for (auto effect : EnabledFX)
		{
			UNiagaraComponent::Get(effect).Deactivate();
		}
	}

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			OverlappingPlayers.Remove(Player);
			Player.SetCapabilityActionState(n"SpeakerHover", EHazeActionState::Inactive);
		}
    }
}

class UCharacterMusicLaunchedGroundPoundBlocker : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	UHazeBaseMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		MoveComp = UHazeBaseMovementComponent::GetOrCreate(Owner);
	}
/*
	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (ConsumeAction(BlockActivationTag) == EActionStateStatus::Active)
			Owner.UnblockCapabilities(MovementSystemTags::GroundPound, BlockGPTag);
	}
*/
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(BlockActivationTag))
			return EHazeNetworkActivation::ActivateLocal;
		
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ConsumeAction(BlockActivationTag);
		Owner.BlockCapabilities(MovementSystemTags::GroundPound, BlockGPTag);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if (ActiveDuration > 0.7f)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(MovementSystemTags::GroundPound, BlockGPTag);
	}
}
