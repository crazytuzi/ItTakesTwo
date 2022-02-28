import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannon;
import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannonShooterComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.CastleAbilityCapability;

class UCastleCannonShootCapability : UCastleAbilityCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"CannonShoot");


	default CapabilityDebugCategory = n"Cannon";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UCastleCannonShooterComponent ShooterComponent;

	float AttacksPerSecond = 4;
	float ShotTimer = 0;

	default SlotName = n"BasicAttack";


	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (ShotTimer > 0)
			ShotTimer -= DeltaTime;

		if (SlotWidget != nullptr)
		{
			SlotWidget.CooldownDuration = 1 / AttacksPerSecond; 
			SlotWidget.CooldownCurrent = ShotTimer;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		UCastleAbilityCapability::Setup(SetupParams);
		
		ShooterComponent = UCastleCannonShooterComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(AttributeNames::PrimaryLevelAbilityAxis))
			return EHazeNetworkActivation::DontActivate;

		if (ShotTimer > 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (ShooterComponent.ActiveCannon == nullptr)
			return;

		ShooterComponent.ActiveCannon.ShootCannon();
		ShotTimer = 1 / AttacksPerSecond;

		CastleComponent.AddUltimateCharge(25);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{


	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	

		
	}
}
