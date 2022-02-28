import Cake.LevelSpecific.SnowGlobe.Magnetic.Underwater.MagneticBuoyComponent;
import Peanuts.Audio.HazeAudioEffects.DopplerDataComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Underwater.MagneticBuoyMovementComponent;

UCLASS(Abstract)
class AMagneticBuoy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComponent;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent CapsuleComponent;
	default CapsuleComponent.CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default CapsuleComponent.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;
	default CapsuleComponent.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UHazeOffsetComponent OffsetComponent;
	default OffsetComponent.DefaultTime = 0.2f;

	UPROPERTY(DefaultComponent, Attach = OffsetComponent)
	UHazeStaticMeshComponent MeshComponent;
	default MeshComponent.CollisionProfileName = n"NoCollision";
	default MeshComponent.bGenerateOverlapEvents = false;
	default MeshComponent.bCanBeDisabled = false;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UDopplerDataComponent DopplerDataComp;

	UPROPERTY(DefaultComponent)
	UMagneticBuoyComponent MagneticBuoyComponent;
	default MagneticBuoyComponent.PlayerImpulse = PlayerImpulse;
	default MagneticBuoyComponent.MinValidPlayerDistance = MinValidPlayerDistance;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMagneticBuoyMovementComponent MagneticBuoyMovementComponent;


	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 12000.f;
	default DisableComp.bActorIsVisualOnly = true;

	UPROPERTY()
	float PlayerImpulse = 8000.f;

	UPROPERTY()
	float MinValidPlayerDistance = 500.f;
}