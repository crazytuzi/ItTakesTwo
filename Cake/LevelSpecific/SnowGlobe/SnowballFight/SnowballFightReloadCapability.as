import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightComponent;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballPickupInteraction;
import Vino.Movement.MovementSystemTags;

class USnowballFigthReloadCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnowballFigthReloadCapability");
	default CapabilityTags.Add(n"SnowballFight");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"GamePlay";
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	USnowballFightComponent SnowballFightComponent;
	ASnowballPickupInteraction PickupActor;
	FHazeAnimationDelegate BlendingOutDelegate;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SnowballFightComponent = USnowballFightComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(n"ReloadingSnowball")) 
			return EHazeNetworkActivation::ActivateFromControl;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"ReloadingSnowball"))
			return EHazeNetworkDeactivation::DeactivateFromControl;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PickupActor = Cast<ASnowballPickupInteraction>(GetAttributeObject(n"PickupActor"));

		// if(PickupActor == nullptr || SnowballFightComponent == nullptr)
		// 	return;
		
		Player.BlockCapabilities(n"SnowGlobeSideContent", this);
		PickupActor.InteractionComp.DisableForPlayer(Player, n"InUse");
		FVector InteractionDirection = PickupActor.ActorLocation - Player.ActorLocation;
		InteractionDirection.Normalize();
		InteractionDirection = Player.ActorRotation.UnrotateVector(InteractionDirection);

		auto SnowballLocomotionFeature = SnowballFightComponent.ThrowLocomotionFeatures[Player.Player];
		FHazePlayOverrideAnimationParams OverrideParams;

		OverrideParams.Animation = SelectAnimationToPlay(SnowballLocomotionFeature, InteractionDirection);
		OverrideParams.BoneFilter = Player.IsAnyCapabilityActive(MovementSystemTags::Crouch) ? EHazeBoneFilterTemplate::BoneFilter_UpperBody : EHazeBoneFilterTemplate::BoneFilter_Spine;
		OverrideParams.BlendTime = 0.08f;
		OverrideParams.BlendOutTime = 0.3f;

		BlendingOutDelegate.BindUFunction(this, n"OnBlendingOut");

		Player.PlayOverrideAnimation(BlendingOutDelegate, OverrideParams);

		SnowballFightComponent.CurrentSnowballAmount = SnowballFightComponent.MaxSnowballAmount;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"SnowGlobeSideContent", this);
		PickupActor.InteractionComp.EnableForPlayer(Player, n"InUse");
		PickupActor = nullptr;

		if(BlendingOutDelegate.IsBound())
			BlendingOutDelegate.Clear();
	}

	UAnimSequence SelectAnimationToPlay(ULocomotionFeatureSnowBallThrow SnowballLocomotionFeature, FVector InteractionDirectionVector)
	{
		if(FMath::Abs(InteractionDirectionVector.Y) > 0.5f)
		{
			if(InteractionDirectionVector.Y > 0)
				return SnowballLocomotionFeature.ReloadRight;
			else
				return SnowballLocomotionFeature.ReloadLeft;
		}
		else
		{
			if(InteractionDirectionVector.X > 0.0f)
				return SnowballLocomotionFeature.ReloadFwd;
			else
				return SnowballLocomotionFeature.ReloadBck;
		}
	}

	UFUNCTION()
	void OnBlendingOut()
	{
		Player.SetCapabilityActionState(n"ReloadingSnowball", EHazeActionState::Inactive);
		if(BlendingOutDelegate.IsBound())
			BlendingOutDelegate.Clear();
	}
}