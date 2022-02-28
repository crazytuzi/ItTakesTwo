import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticEffects;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Vino.Interactions.Widgets.InteractionContextualWidget;

class UMagnetEffectCapability : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	default CapabilityTags.Add(FMagneticTags::MagneticEffect);
	
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 90;

	UMagneticPlayerComponent PlayerMagnetComp;
	AHazePlayerCharacter Player;
	UMagneticComponent LastMagnet;

	UPROPERTY()
	TSubclassOf<AMagneticEffects> MagneticEffectClass;

	UPROPERTY(Transient)
	AMagneticEffects MagneticEffect;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerMagnetComp = UMagneticPlayerComponent::GetOrCreate(Player);

		MagneticEffect = Cast<AMagneticEffects>(SpawnActor(MagneticEffectClass, Player.ActorLocation + FVector(0,0,100), Player.ActorRotation));
		MagneticEffect.AttachToActor(Player, NAME_None, EAttachmentRule::KeepWorld);
		MagneticEffect.DisableActor(this);

		UMagneticPlayerComponent PlayerMagnet = UMagneticPlayerComponent::Get(Player);
		MagneticEffect.Initialize(Player, PlayerMagnet.HasPositivePolarity());
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if(MagneticEffect != nullptr)
		{
			MagneticEffect.DeactivateMagneticEffect();
			MagneticEffect.DetachFromActor();
			MagneticEffect.DestroyActor();
			MagneticEffect = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		UMagneticComponent CurrentActiveMagnet = Cast<UMagneticComponent>(PlayerMagnetComp.GetActivatedMagnet());	
		if(CurrentActiveMagnet != nullptr)
		 	return EHazeNetworkActivation::ActivateLocal;

		UMagneticComponent CurrentTargetMagnet = Cast<UMagneticComponent>(PlayerMagnetComp.GetTargetedMagnet());
		if(CurrentTargetMagnet != nullptr)
		 	return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		UMagneticComponent CurrentActiveMagnet = Cast<UMagneticComponent>(PlayerMagnetComp.GetActivatedMagnet());
		if(CurrentActiveMagnet != nullptr)
       		return EHazeNetworkDeactivation::DontDeactivate;

		UMagneticComponent CurrentTargetMagnet = Cast<UMagneticComponent>(PlayerMagnetComp.GetTargetedMagnet());
		if(CurrentTargetMagnet != nullptr)
       		return EHazeNetworkDeactivation::DontDeactivate;

        return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LastMagnet = nullptr;
		PlayerMagnetComp.PlayerMagnet.OnMagnetVisualStarted.Broadcast();
		MagneticEffect.EnableActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MagneticEffect.DeactivateMagneticEffect();
		PlayerMagnetComp.PlayerMagnet.OnMagnetVisualStopped.Broadcast();

		// Reset normal distance value
		PlayerMagnetComp.PlayerMagnet.NormalDistanceToTargetMagnet = 1.f;
		MagneticEffect.DisableActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Set the effect on the active magnet. 
		// Skip updating targeted magnet if a magnet is active.
		if(UpdateActiveMagnet())
			return;

		// Update target effect on the current target if no magnet is active
		UpdateTargetMagnet();
	}

	// Returns true if a magnet is being activated
	bool UpdateActiveMagnet()
	{
		UMagneticComponent CurrentActiveMagnet = Cast<UMagneticComponent>(PlayerMagnetComp.GetActivatedMagnet());
		if(CurrentActiveMagnet != LastMagnet)
		{
			MagneticEffect.DeactivateMagneticEffect();

			if(CurrentActiveMagnet == nullptr)
				return false;

			LastMagnet = CurrentActiveMagnet;

			MagneticEffect.ActivateMagneticEffect(CurrentActiveMagnet.Owner, PlayerMagnetComp, LastMagnet, true);
			return true;
		}

		return CurrentActiveMagnet != nullptr;
	}

	void UpdateTargetMagnet()
	{			
		UMagneticComponent CurrentTargetMagnet = Cast<UMagneticComponent>(PlayerMagnetComp.GetTargetedMagnet());
		if(CurrentTargetMagnet != nullptr)
		{
			LastMagnet = nullptr;
			MagneticEffect.ActivateMagneticEffect(CurrentTargetMagnet.Owner, PlayerMagnetComp, CurrentTargetMagnet, false);

			// Update distance to magnet
			PlayerMagnetComp.PlayerMagnet.NormalDistanceToTargetMagnet = Math::Saturate(Player.ActorLocation.Distance(CurrentTargetMagnet.WorldLocation) / CurrentTargetMagnet.GetDistance(EHazeActivationPointDistanceType::Selectable));
		}
	}
}