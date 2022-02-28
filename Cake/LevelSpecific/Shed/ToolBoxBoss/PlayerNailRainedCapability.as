import Cake.LevelSpecific.Shed.ToolBoxBoss.PlayerNailRainedComponent;
import Cake.LevelSpecific.Shed.ToolBoxBoss.ToolBoxNailRainNew;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.Animation.Features.Shed.LocomotionFeatureToolBossNailed;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Pierceables.PierceStatics;

class AToolBoxRainAnimatedNail : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
}

class PlayerNailRainedCapability : UHazeCapability
{
	default CapabilityTags.Add(n"NailRained");

	default CapabilityDebugCategory = n"NailRained";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UPlayerNailRainedComponent NailRainComp;
	ULocomotionFeatureToolBossNailed NailedFeature;

	UButtonMashProgressHandle ButtonMash;

	AToolBoxRainAnimatedNail AnimatedNail;
	AToolBoxRainNailNew ActiveNail;

	const float DefaultCapsuleRadius = 30.f;

	bool bPlayerPresumedDead = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		NailRainComp = UPlayerNailRainedComponent::GetOrCreate(Player);

		AnimatedNail = Cast<AToolBoxRainAnimatedNail>(SpawnActor(AToolBoxRainAnimatedNail::StaticClass()));
		AnimatedNail.DisableActor(this);
		AnimatedNail.Mesh.StaticMesh = NailRainComp.AnimatedNailMesh;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (NailRainComp.HitNail == nullptr) 
			return EHazeNetworkActivation::DontActivate;

		if (!CanPlayerBeKilled(Player))
			return EHazeNetworkActivation::DontActivate;

		if (!CanPlayerBeDamaged(Player))
			return EHazeNetworkActivation::DontActivate;

    	return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Player.IsPlayerDead())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (NailRainComp.HitNail == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (ButtonMash.Progress >= 1.f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!CanPlayerBeKilled(Player))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		// Damage is replicated from ControlSide so we need to deal damage first, then check if the player has died or not.
		Player.DamagePlayerHealth(0.5f);
		const bool bIsPlayerDead = Player.IsPlayerDead();

		if(bIsPlayerDead)
		{
			Params.AddActionState(n"IsPlayerDead");
		}
		else
		{
			Params.AddObject(n"Nail", NailRainComp.HitNail);

			auto Nail = Cast<AToolBoxRainNailNew>(NailRainComp.HitNail);
			Params.AddValue(n"FallTime", Nail.FallTime);
		}

		Params.DisableTransformSynchronization();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		Player.PlayForceFeedback(NailRainComp.ForceFeedBackEffect, false, true, n"NailRained", 1.f);

		bPlayerPresumedDead = Params.GetActionState(n"IsPlayerDead");

		// Early out if we are expected to get killed
		if(bPlayerPresumedDead)
			return;


		ActiveNail = Cast<AToolBoxRainNailNew>(Params.GetObject(n"Nail"));
		if (!HasControl())
		{
			ActiveNail.HitPlayer = Player;
			NailRainComp.HitNail = ActiveNail;
		}

		//Animation		
		NailedFeature = Player.IsCody() ? NailRainComp.CodyFeature : NailRainComp.MayFeature;
		Player.AddLocomotionFeature(NailedFeature);

		Player.BlockCapabilities(n"Movement", this);
		Player.BlockCapabilities(n"Weapon", this);
		Player.BlockCapabilities(n"HammeredPlayer", this);
		Player.BlockCapabilities(n"PiercedPlayer", this);
		
		Player.SetCapabilityActionState(n"FoghornSBNailMayHammerhead", EHazeActionState::ActiveForOneFrame);

		Player.ApplyCameraSettings(NailRainComp.CamSettings, FHazeCameraBlendSettings(0.5f), this, EHazeCameraPriority::Maximum);
		Player.BlockCapabilities(CameraTags::PointOfInterest, this);

		NailRainComp.bIsAttachedToNail = true;
		ButtonMash = StartButtonMashProgressAttachToActor(Player, Player, FVector::ZeroVector);
		ButtonMash.bSyncOverNetwork = true;

		AnimatedNail.EnableActor(this);
		AnimatedNail.AttachToComponent(Player.Mesh, n"Align");
		System::SetTimer(this, n"StartTakingTickDamage", 2.f, true);

		// Attach to the nail!
		Player.TriggerMovementTransition(this, n"NailRained");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(bPlayerPresumedDead)
			return;

		Player.RemoveLocomotionFeature(Player.IsCody() ? NailRainComp.CodyFeature : NailRainComp.MayFeature);
		Player.ClearCameraSettingsByInstigator(this);

		// Reset the hit player on the nail, so it can disappear
		if (ActiveNail != nullptr)
		{
			ActiveNail.HitPlayer = nullptr;
			ActiveNail.DeactivateNail();
		}

		NailRainComp.HitNail = nullptr;

		Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(n"Weapon", this);
		Player.UnblockCapabilities(n"HammeredPlayer", this);
		Player.UnblockCapabilities(n"PiercedPlayer", this);

		Player.UnblockCapabilities(CameraTags::PointOfInterest, this);

		NailRainComp.bIsAttachedToNail = false;

		ButtonMash.StopButtonMash();
		AnimatedNail.DisableActor(this);

		Player.AddPlayerInvulnerabilityDuration(2.f);

		System::ClearTimer(this, n"StartTakingTickDamage");
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActive() || NailRainComp.HitNail == nullptr)
			return;

		if (!CanPlayerBeKilled(Player) || Player.IsPlayerDead() || IsBlocked())
		{
			auto Nail = Cast<AToolBoxRainNailNew>(NailRainComp.HitNail);

			NailRainComp.HitNail = nullptr;
			Nail.DeactivateNail();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bPlayerPresumedDead)
			return;

		//Animation
		FHazeRequestLocomotionData LocoData;
		LocoData.AnimationTag = n"ToolBossNailed";
		Player.RequestLocomotion(LocoData);

		// Update mashing
		ButtonMash.Progress += ButtonMash.MashRateControlSide * 0.1f * DeltaTime;
		NailRainComp.BlendSpaceValue = ButtonMash.Progress;

		Player.SetFrameForceFeedback(ButtonMash.Progress / 2, ButtonMash.Progress);
		Player.ActorLocation = ActiveNail.ActorLocation;
	}

	UFUNCTION()
	void StartTakingTickDamage()
	{
		Player.DamagePlayerHealth(1.f/12.f);
		Player.PlayForceFeedback(NailRainComp.ForceFeedBackEffect, false, false, n"HealthTick");
	}
}