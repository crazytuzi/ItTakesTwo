import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingBeetle;
import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingHealthWidget;

class UTreeBeetleRidingComponent : UActorComponent
{
	UPROPERTY()
	ATreeBeetleRidingBeetle Beetle;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionStateMachineAsset LocomotionAssetMay;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionStateMachineAsset LocomotionAssetCody;

	UPROPERTY(Category = "Widget")
	TSubclassOf<UTreeBeetleRidingHealthWidget> HealthWidgetClass;

	UPROPERTY()
	FVector2D AimSpaceValue;

	bool bIsOnBeetle;
}

UFUNCTION()
void StartRidingBeetle(AHazePlayerCharacter Player, ATreeBeetleRidingBeetle Beetle)
{
	UTreeBeetleRidingComponent BeetleRidingComponent = UTreeBeetleRidingComponent::Get(Player);

	BeetleRidingComponent.Beetle = Beetle;
	BeetleRidingComponent.bIsOnBeetle = true;
}

UFUNCTION()
void StopRidingBeetle(AHazePlayerCharacter Player)
{
	UTreeBeetleRidingComponent BeetleRidingComponent = UTreeBeetleRidingComponent::Get(Player);

	// BeetleRidingComponent.Beetle = nullptr;
	BeetleRidingComponent.bIsOnBeetle = false;
	BeetleRidingComponent.Beetle = nullptr;
}