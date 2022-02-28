import Cake.LevelSpecific.Clockwork.FlyingBomb.FlyingBomb;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingComponent;
import Cake.LevelSpecific.Clockwork.FlyingBomb.FlyingBombHitResponseComponent;

class UFlyingBombExplodeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FlyingBombExplode");
	default CapabilityDebugCategory = n"FlyingBomb";

	default TickGroup = ECapabilityTickGroups::ReactionMovement;

	AFlyingBomb Bomb;
	AHazePlayerCharacter HitPlayer;
	UObject HitObject;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Bomb = Cast<AFlyingBomb>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(n"Explode"))
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"Explode"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"HitObject", GetAttributeObject(n"HitObject"));
		ActivationParams.SetCrumbTransformValidation(EHazeActorReplicationSyncTransformType::AttemptWait_SmoothTeleport);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		HitObject = ActivationParams.GetObject(n"HitObject");
		HitPlayer = Cast<AHazePlayerCharacter>(HitObject);

		if (HitPlayer != nullptr)
		{
			auto HitTracker = UBirdFlyingBombTrackerComponent::Get(HitPlayer);
			if (HitTracker.HeldBomb != nullptr && HitTracker.HeldBomb != Bomb)
			{
				HitTracker.HeldBomb.SetCapabilityActionState(n"Explode", EHazeActionState::Active);
			}

			auto Bird = GetPlayerBird(HitPlayer);
			if (Bird != nullptr)
			{
				Bird.SetCapabilityActionState(n"HitByExplosion", EHazeActionState::Active);
			}
		}
		else if (Cast<AActor>(HitObject) != nullptr)
		{
			auto HitActor = Cast<AActor>(HitObject);
			auto ResponseComp = UFlyingBombHitResponseComponent::Get(HitActor);
			if (ResponseComp != nullptr)
			{
				ResponseComp.OnHitByFlingBomb.Broadcast(Bomb.ActorLocation, Bomb.LastHeldPlayer);
			}
		}


		Bomb.State = EFlyingBombState::Exploded;
		Bomb.SetActorHiddenInGame(true);

		Bomb.BlockCapabilities(n"FlyingBombAI", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ConsumeAction(n"Explode");

		UObject Attribute;
		ConsumeAttribute(n"HitObject", Attribute);
		HitPlayer = nullptr;
		HitObject = nullptr;

		Bomb.TeleportActor(Bomb.StartPosition, Bomb.StartRotation);
		Bomb.VisualRoot.RelativeRotation = FRotator();
		Bomb.SetActorHiddenInGame(false);
		Bomb.State = EFlyingBombState::Idle;

		Bomb.UnblockCapabilities(n"FlyingBombAI", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > Bomb.RespawnDelay)
		{
			ConsumeAction(n"Explode");
		}

		if (ActiveDuration < 1.f && HitPlayer != nullptr)
			HitPlayer.SetFrameForceFeedback(1.f, 1.f);
	}
};