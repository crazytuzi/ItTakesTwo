import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlant;
import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.JoysRoomBridge;
import Peanuts.Animation.Features.Garden.LocomotionFeatureGardenVinesSwiper;
import Vino.PlayerHealth.PlayerHealthComponent;

event void FOnSwiperArmHitPlayer(AHazePlayerCharacter Player);

UCLASS(Abstract)
class ABossControllablePlantSwiper : ABossControllablePlant
{
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HeadRoot;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	UCapsuleComponent SwiperCollider;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UArrowComponent HitDirection;

	UPROPERTY(Category="Swiper")
	bool bPlayerIsOnBridge = false;

	UPROPERTY(Category="Swiper")
	bool bIsRightArm = false;

	UPROPERTY(Category="Swiper")
	TArray<AHazePlayerCharacter> PlayersOnBridge;

	UPROPERTY(Category="Swiper")
	ULocomotionFeatureGardenVinesSwiper LocomotionFeature;

	UPROPERTY(Category="Swiper")
	AJoysRoomBridge Bridge;

	UPROPERTY(Category="Swiper")
	ABossControllablePlantSwiper OtherSwiperArm;

	UPROPERTY(Category="Swiper")
	FOnSwiperArmHitPlayer OnSwiperArmHitPlayer;

	UPROPERTY(Category="Swiper")
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		HeadRoot.AttachToComponent(SkeletalMesh, n"Head", EAttachmentRule::SnapToTarget);

		// if(!bIsRightArm)
		// {
			AddCapability(n"BossControllablePlantButtonMashCapability");
		// }

		AddCapability(n"BossControllablePlantSwiperCapability");

		Bridge.OnPlayerEnteredBridge.AddUFunction(this, n"PlayerEnteredBridge");
		Bridge.OnPlayerLeftBridge.AddUFunction(this, n"PlayerLeftBridge");
	}


	UFUNCTION()
	void PlayerEnteredBridge(AHazePlayerCharacter Player)
	{
		PlayersOnBridge.Add(Player);
		bPlayerIsOnBridge = true;
	}

	UFUNCTION()
	void PlayerLeftBridge(AHazePlayerCharacter Player)
	{
		PlayersOnBridge.Remove(Player);

		if(PlayersOnBridge.Num() <= 0)
			bPlayerIsOnBridge = false;
	}
}