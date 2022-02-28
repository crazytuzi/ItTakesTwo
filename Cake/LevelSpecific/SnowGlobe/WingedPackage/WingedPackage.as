import Vino.Pickups.PickupActor;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Spline.SplineComponent;
import Vino.Movement.Components.MovementComponent;
import Peanuts.Spline.SplineActor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetPickupComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PickUp.MagneticPickupActor;

enum EWingedPackageState
{
	FlyingInCircle,
	PickedUpByPlayer,
	FlyUpInAir
};

class AWingedPackage : AMagneticPickupActor
{
	UPROPERTY()
	bool bIsGrounded;

	UPROPERTY(DefaultComponent)
	UBoxComponent MovementComponentCollider;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent Movecomp;

	UPROPERTY()
	ASplineActor FlyInCircleSplineActor;

	default MagnetPickupComponentCody.Polarity = EMagnetPolarity::Minus_Blue;
	default MagnetPickupComponentMay.Polarity = EMagnetPolarity::Plus_Red;

	default MagnetPickupComponentCody.ValidationType = EHazeActivationPointActivatorType::Cody;
	default MagnetPickupComponentMay.ValidationType = EHazeActivationPointActivatorType::May;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Movecomp.Setup(MovementComponentCollider);

		Super::BeginPlay();
	}

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
	{

	}

	UFUNCTION()
	void SetPackageState()
	{

	}

	UFUNCTION(BlueprintEvent)
	void FlapWings()
	{

	}

	UFUNCTION(BlueprintEvent)
	void SetGlideState(bool ShouldGlide)
	{

	}
}