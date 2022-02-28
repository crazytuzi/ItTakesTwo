import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;
import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.PaintableGooComponent;

class UTomatoGooDamageDisableCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 0;
	
	ATomato Tomato;
	UTomatoSettings Settings;
	UPaintableGooComponent GooComp;

	float Elapsed = 0.0f;

	bool bWasInGoo = false;
	bool bCanDisableDamage = true;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Tomato = Cast<ATomato>(Owner);
		GooComp = UPaintableGooComponent::GetOrCreate(Tomato.OwnerPlayer);
		Settings = UTomatoSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!GooComp.bIsStandingInGoo)
			return EHazeNetworkActivation::DontActivate;

		if(!bCanDisableDamage)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Elapsed = 0.0f;
		Owner.SetCapabilityActionState(n"DisableDashDamage", EHazeActionState::Active);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Elapsed >= Settings.DashDisableTime)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!GooComp.bIsStandingInGoo)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bWasInGoo = true;
		bCanDisableDamage = false;
		Owner.SetCapabilityActionState(n"DisableDashDamage", EHazeActionState::Inactive);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Elapsed += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(bWasInGoo && !GooComp.bIsStandingInGoo)
		{
			bCanDisableDamage = !GooComp.bIsStandingInGoo;
			bWasInGoo = false;
		}
	}
}
