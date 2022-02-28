import Cake.LevelSpecific.SnowGlobe.SnowTurtle.SnowTurtleBaby;
import Cake.LevelSpecific.SnowGlobe.SnowTurtle.SnowTurtleNest;

class ASnowTurtleMother : AHazeCharacter
{
	AHazePlayerCharacter PlayerMay;
	AHazePlayerCharacter PlayerCody;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BreatheLoopStart;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BreatheLoopStop;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UHazeCharacterSkeletalMeshComponent SkeletalMeshComp;
	default SkeletalMeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)	
	USnowballFightResponseComponent SnowballFightResponseComponent;

	UPROPERTY(DefaultComponent)	
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 12000.f;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent MotherTurtleImpactReaction;

	UPROPERTY()
	TSubclassOf<UHazeCapability> CapabilityToAdd;

	bool bIsHappy;

	bool bQuestComplete;

	bool bHasAllBabies;

	UPROPERTY()
	TArray<ASnowTurtleNest> NestsArray;

	bool bCanTriggerSnowballhit;

	float Timer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerMay = Game::GetMay();
		PlayerCody = Game::GetCody();
		HazeAkComp.HazePostEvent(BreatheLoopStart);
		SnowballFightResponseComponent.OnSnowballHit.AddUFunction(this, n"HitBySnowBall");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bCanTriggerSnowballhit)
		{
			Timer -= DeltaTime;

			if (Timer <= 0.f)
				bCanTriggerSnowballhit = false;
		}
	}

	UFUNCTION()
	void HitBySnowBall(AActor ProjectileOwner, FHitResult Hit, FVector HitVelocity)
	{
		SkeletalMeshComp.SetAnimBoolParam(n"bHitBySnowball", true);
		
		if (!bCanTriggerSnowballhit)
		{
			bCanTriggerSnowballhit = true;
			Timer = 2.f;
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		HazeAkComp.HazePostEvent(BreatheLoopStop);
	}
}