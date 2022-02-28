import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlant;
import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlantPlayerComponent;
import Vino.PlayerHealth.PlayerHealthComponent;
import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.MovePlantWidget;

event void FOnHammerArmHitPlayer(AHazePlayerCharacter Player);

UCLASS(Abstract)
class ABossControllablePlantHammer : ABossControllablePlant
{
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HeadRoot;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	UCapsuleComponent HammerCollider;

	UPROPERTY(Category="Widget")
	TSubclassOf<UMovePlantWidget> MovementWidgetClass;

	UPROPERTY(Category="Hammer")
	bool bPlayerIsInRange = false;

	UPROPERTY(Category="Hammer")
	float CurrentRotationValue = 0.0f;

	UPROPERTY(Category="Hammer")
	float RotationSpeed = 0.5f;

	UPROPERTY(Category="Hammer")
	float MaxYawValue = 50.0f;

	UPROPERTY(Category="Hammer")
	float PlayerInRangeDistance = 800.0f;

	UPROPERTY(Category="Hammer")
	float HitRange = 500.0f;

	UPROPERTY(Category="Hammer")
	FOnHammerArmHitPlayer OnHammerArmHitPlayer;

	UPROPERTY(Category="Hammer")
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		HeadRoot.AttachToComponent(SkeletalMesh, n"Head", EAttachmentRule::SnapToTarget);

		AddCapability(n"BossControllablePlantButtonMashCapability");
		AddCapability(n"BossControllablePlantHammerMovementCapability");
		AddCapability(n"BossControllablePlantHammerSmashingCapability");
	}

}