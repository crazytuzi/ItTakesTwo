import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Movement.SplineLock.SplineLockComponent;
import Rice.Math.MathStatics;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;

class UIceSkatingGrindLockCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Movement);
	default CapabilityTags.Add(GrindingCapabilityTags::Jump);

	default CapabilityDebugCategory = n"IceSkating";	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 90;

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	USplineLockComponent SplineLockComp;

	UHazeSplineComponent CurrentLockedSpline = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
		SplineLockComp = USplineLockComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{		
		if (!UserGrindComp.HasActiveGrindSpline())
       		return EHazeNetworkActivation::DontActivate;

		if (UserGrindComp.ActiveGrindSpline.Spline == nullptr)
       		return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (UserGrindComp.HasActiveGrindSpline() &&
			UserGrindComp.ActiveGrindSpline.Spline != CurrentLockedSpline)
       		return EHazeNetworkDeactivation::DeactivateLocal;

        return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FConstraintSettings Settings;
		Settings.SplineToLockMovementTo = UserGrindComp.ActiveGrindSpline.Spline;
		Settings.ConstrainType = EConstrainCollisionHandlingType::FreeVertical;
		Settings.bLockToEnds = false;

		SplineLockComp.LockOwnerToSpline(Settings);
		CurrentLockedSpline = UserGrindComp.ActiveGrindSpline.Spline;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SplineLockComp.StopLocking();
		CurrentLockedSpline = nullptr;
	}
}
