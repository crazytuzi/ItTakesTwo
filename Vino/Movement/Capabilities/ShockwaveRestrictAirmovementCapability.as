import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSettings;

class ShockwaveRestrictAirmovementCapability : UHazeCapability
{
// Capabilites are ticked in order of a tick group, 	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

    UHazeMovementComponent MovementComponent;
    FVector LaunchForce = FVector(0,0,0);
    float TimeSinceLaunched = 0;
    float AircontrolAmount = 0;
    float RestrictedAirControlAmount = 1700;
    bool HasLanded = false;

    default CapabilityTags.Add(n"Movement");

	default CapabilityDebugCategory = CapabilityTags::Movement;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        TimeSinceLaunched = 0;
        HasLanded = false;
        MovementComponent = UHazeMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UMovementSettings::SetAirControlLerpSpeed(Owner, RestrictedAirControlAmount, Instigator = this);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		Owner.ClearSettingsByInstigator(this);
        HasLanded = false;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (MovementComponent.GetPreviousImpulse(n"ChockWaveForce").Size() > 0)
        return EHazeNetworkActivation::ActivateLocal;

        else
        return EHazeNetworkActivation::DontActivate;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        if (HasLanded)
        {
            return EHazeNetworkDeactivation::DeactivateLocal;
        }

        else
            return EHazeNetworkDeactivation::DontDeactivate;
    }

    UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
    {
        TimeSinceLaunched += DeltaTime;

        if (TimeSinceLaunched > 0.5f)
        {
            if (UHazeMovementComponent::Get(Owner).IsGrounded())
            {
                HasLanded = true;
                TimeSinceLaunched = 0;
            }
        }
    }

}