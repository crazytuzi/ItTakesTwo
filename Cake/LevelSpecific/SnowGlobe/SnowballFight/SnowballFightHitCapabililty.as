import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightManagerComponent;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightArenaVolume;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightComponent;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightNames;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Swinging.SwingComponent;
import Vino.Movement.MovementSystemTags;
import Peanuts.Foghorn.FoghornStatics;

class USnowballFightHitCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(SnowballFightTags::Hit);
	default CapabilityTags.Add(n"SnowballFight");

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	USnowballFightComponent SnowballFightComponent;
	USnowballFightResponseComponent ResponseComp;
	UAutoAimTargetComponent AutoAimComp;
	USwingingComponent SwingComp;
	UUserGrindComponent UserGrindComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SnowballFightComponent = USnowballFightComponent::Get(Owner);
		ResponseComp = USnowballFightResponseComponent::GetOrCreate(Owner);
		AutoAimComp = UAutoAimTargetComponent::Get(Owner);
		SwingComp = USwingingComponent::Get(Owner);
		UserGrindComp = UUserGrindComponent::Get(Owner);
		
		ResponseComp.OnSnowballHit.AddUFunction(this, n"HandleProjectileHit");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SwingComp != nullptr && SwingComp.IsSwinging())
			return EHazeNetworkActivation::DontActivate;

		if (UserGrindComp != nullptr && UserGrindComp.HasActiveGrindSpline())
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(SnowballFightAction::Hit))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SwingComp != nullptr && SwingComp.IsSwinging())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (UserGrindComp != nullptr && UserGrindComp.HasActiveGrindSpline())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// Deactivate with the knockdown capability, is there a better way to do this?
		if (!Player.IsAnyCapabilityActive(n"KnockDown"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		FVector Velocity;
		ConsumeAttribute(SnowballFightAttribute::HitVelocity, Velocity);

		UObject Instigator;
		ConsumeAttribute(SnowballFightAttribute::HitInstigator, Instigator);

		Params.AddVector(n"HitVelocity", Velocity);
		Params.AddObject(n"HitInstigator", Instigator);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params) 
	{
		FVector HitVelocity = Params.GetVector(n"HitVelocity");

		if (HitVelocity.IsNearlyZero())
			HitVelocity = -Player.ActorForwardVector;

		// Owner of the projectile that hit us
		UObject Instigator = Params.GetObject(n"HitInstigator");

		// Snowball fight scoring, only relevant within the minigame
		// and when the instigator is a player, score add called from manager comp control side
		if (Cast<AHazePlayerCharacter>(Instigator) != nullptr)
		{
			auto ManagerComp = GetFightManagerComponent();
			
			if (ManagerComp != nullptr &&
				ManagerComp.HasControl() &&
				ManagerComp.BothPlayersInArea &&
				ManagerComp.GameStarted)
			{
				if (Player.IsCody())
					ManagerComp.NetAddMayScore(ManagerComp.ScorePerHit);
				else
					ManagerComp.NetAddCodyScore(ManagerComp.ScorePerHit);
			}
		}

		// We're not a valid target when downed
		AutoAimComp.SetAutoAimEnabled(false);

		// Hit reaction must be called as effort, otherwise it'll override taunt/hit dialogue
		PlayFoghornEffort(Player.IsMay() ? SnowballFightComponent.MayHitReactionVO : SnowballFightComponent.CodyHitReactionVO, nullptr);
		Player.PlayForceFeedback(SnowballFightComponent.HitRumble, false, true, SnowballFightTags::Hit);

		// Knockdown is handled by CharacterKnockDownCapability
		FVector ImpactForce = HitVelocity.GetSafeNormal() * 700.f;
		Player.SetCapabilityActionState(n"KnockDown", EHazeActionState::Active);
		Player.SetCapabilityAttributeVector(n"KnockdownDirection", ImpactForce);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AutoAimComp.SetAutoAimEnabled(true);
	}

	UFUNCTION()
	private void HandleProjectileHit(AActor ProjectileOwner, FHitResult Hit, FVector HitVelocity)
	{
		if (!HasControl() || ProjectileOwner == Player)
			return;

		Player.SetCapabilityActionState(SnowballFightAction::Hit, EHazeActionState::ActiveForOneFrame);
		Player.SetCapabilityAttributeVector(SnowballFightAttribute::HitVelocity, HitVelocity);
		Player.SetCapabilityAttributeObject(SnowballFightAttribute::HitInstigator, ProjectileOwner);
	}

	private USnowballFightManagerComponent GetFightManagerComponent()
	{
		auto Arena = Cast<ASnowballFightArenaVolume>(GetAttributeObject(n"ArenaActor"));

		if (Arena == nullptr)
			return nullptr;

		return USnowballFightManagerComponent::Get(Arena);
	}
};