import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannon;
import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannonShooterComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.CastleAbilityCapability;

class UCastleCannonShootBeamCapability : UCastleAbilityCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"CannonShoot");


	default CapabilityDebugCategory = n"Cannon";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 99;

	AHazePlayerCharacter Player;
	UCastleCannonShooterComponent ShooterComponent;
	ACastleCannon Cannon;

	float ChargeCostPerSecond = 10.f;


	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ShooterComponent = UCastleCannonShooterComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (true)
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(AttributeNames::SecondaryLevelAbilityAxis))
			return EHazeNetworkActivation::DontActivate;

		if (CastleComponent.UltimateCharge <= 0)
			return EHazeNetworkActivation::DontActivate;		

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (CastleComponent.UltimateCharge <= 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Cannon != ShooterComponent.ActiveCannon)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (ShooterComponent.ActiveCannon == nullptr)
			return;

		Cannon = ShooterComponent.ActiveCannon;

		Owner.BlockCapabilities(n"CannonShoot", this);

		Cannon.StartBeam();		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Cannon.StopBeam();	

		Cannon = nullptr;	

		Owner.UnblockCapabilities(n"CannonShoot", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		//SpendCharge(DeltaTime);		
	}

	void SpendCharge(float DeltaTime)
	{
		// float ChargeThisFrame = ChargeCostPerSecond * DeltaTime;
		// ShooterComponent.ActiveCannon.SpendCharge(ChargeThisFrame);
	}
}
