import Vino.Movement.Components.MovementComponent;
import Vino.Pickups.PickupActor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetPickupComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Gifts.MagneticGiftComponent;

enum EHeliumPackageState
{
	PickedUpByPlayer,
	Free
};

class AHeliumPackage : APickupActor
{
	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UBoxComponent Collider;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UBoxComponent PlayerCollider;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UBoxComponent PlayerOverlapCollider;

	UPROPERTY(DefaultComponent)
	UMagnetPickupComponent MagneticCompMay;

	UPROPERTY(DefaultComponent)
	UMagnetPickupComponent MagneticCompCody;

	UPROPERTY(DefaultComponent)
	UMagneticGiftComponent GiftComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent FlyTrail;

	UPROPERTY()
	TSubclassOf<UCharacterMovementCapability> RequiredCapability;

	EHeliumPackageState State = EHeliumPackageState::Free;
	
	UPROPERTY()
	TArray<AHazePlayerCharacter> OverlappingPlayers;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MagneticCompCody.Polarity = EMagnetPolarity::Minus_Blue;
		MagneticCompMay.Polarity = EMagnetPolarity::Plus_Red;

		MagneticCompCody.ValidationType = EHazeActivationPointActivatorType::Cody;
		MagneticCompMay.ValidationType = EHazeActivationPointActivatorType::May;
	}


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Capability::AddPlayerCapabilityRequest(RequiredCapability.Get());
		AddCapability(n"HeliumPackageMovementCapability");
		AddCapability(n"HeliumPackageTiltCapability");
	}

	UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(RequiredCapability.Get());
	}

	void SetCurrentState(EHeliumPackageState NewState)
	{
		if(State == NewState)
			return;

		State = NewState;

		if(State == EHeliumPackageState::Free)
			FlyTrail.Activate(true);
		else
			FlyTrail.Deactivate();
	}
}