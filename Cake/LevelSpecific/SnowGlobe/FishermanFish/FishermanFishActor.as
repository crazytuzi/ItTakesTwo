import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;

class AFishermanFishActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)	
	UCapsuleComponent CapsuleComp;
	default CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Root)	
	UHazeCharacterSkeletalMeshComponent SkeletalMesh;
	
	UPROPERTY(DefaultComponent, Attach = SphereComponent)
	UMagnetGenericComponent MagnetComponent;
}