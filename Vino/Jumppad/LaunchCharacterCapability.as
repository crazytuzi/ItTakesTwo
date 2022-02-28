import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.MovementSystemTags;

class ULaunchCharactercapability : UCharacterMovementCapability
{
    default CapabilityTags.Add(CapabilityTags::Movement);

	// Capabilites are ticked in order of a tick group,
	default TickGroup = ECapabilityTickGroups::ReactionMovement;

    AHazeCharacter Character;
    FVector LaunchForce = FVector(0,0,0);
    FVector GoalLocation;
    float TimeSinceLaunched = 0;
    float AirControl = 1;
    bool HasLanded = false;

    bool bShouldLaunch = false;
    bool bOverrideAirControl = false;

    FVector ActivateGoalLocation;
    float ActivateAirControl;

    float StoredAirControlAmount;

    default CapabilityTags.Add(CapabilityTags::Movement);

    float LaunchArc = 0.5f;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
        Character = Cast<AHazeCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        Character.BlockCapabilities(MovementSystemTags::GroundMovement, this);
    }
  
    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
        Character.ClearSettingsByInstigator(this);

        Character.UnblockCapabilities(MovementSystemTags::GroundMovement, this);
        HasLanded = true;
    }

    void LaunchCharacter()
    {
        GoalLocation = ActivateGoalLocation;
        AirControl = ActivateAirControl;
        HasLanded = false;
        TimeSinceLaunched = 0;

        if (bOverrideAirControl)
        {
			UMovementSettings::SetAirControlLerpSpeed(Owner, AirControl, Instigator = this);
        }
        else
        {
            UMovementSettings::ClearAirControlLerpSpeed(Owner, Instigator = this);
        }

        if (GoalLocation.X == Character.ActorLocation.X && GoalLocation.Y == Character.ActorLocation.Y)
        {
            LaunchForce = FVector::ZeroVector;
            LaunchForce.Z = GoalLocation.Z;
            MoveComp.AddImpulse(LaunchForce);
        }

        else
        {
            LaunchArc = GetAttributeValue(n"LaunchArc");
            Gameplay::SuggestProjectileVelocity_CustomArc(LaunchForce, Character.ActorLocation, GoalLocation, -Character.ActorGravity.Size(), LaunchArc);
        }

        MoveComp.Velocity = 0;
        MoveComp.AddImpulse(LaunchForce);
    }

    UFUNCTION(BlueprintOverride)
    void PreTick(float DeltaTime)
    {
        if (ConsumeAttribute(n"LaunchGoalLocation", ActivateGoalLocation))
        {
            bShouldLaunch = true;
            if (ConsumeAttribute(n"LaunchAirControl", ActivateAirControl))
            {
                bOverrideAirControl = true;
            }
            else
            {
                bOverrideAirControl = false;
            }
        }
        else
        {
            bShouldLaunch = false;
        }
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (bShouldLaunch)
        {
            return EHazeNetworkActivation::ActivateLocal;
        }
        else
        {
            return EHazeNetworkActivation::DontActivate;
        }
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        const FVector DownVel =  MoveComp.GetVelocity().ConstrainToDirection(MoveComp.GetWorldUp());
        if(DownVel.GetSafeNormal().DotProduct(-MoveComp.GetWorldUp()) > 0.5f)
        {
            return EHazeNetworkDeactivation::DeactivateLocal;
        }

        if (HasLanded)
        {
            return EHazeNetworkDeactivation::DeactivateLocal;
        }
        else
        {
            return EHazeNetworkDeactivation::DontDeactivate;
        }
    }

    UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
    {
        TimeSinceLaunched += DeltaTime;

        if (bShouldLaunch)
        {
            LaunchCharacter();
        }

        if (TimeSinceLaunched > 0.5f)
        {
            if (MoveComp.IsGrounded())
            {
                HasLanded = true;
            }
        }
    }
}