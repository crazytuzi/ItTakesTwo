import Cake.LevelSpecific.SnowGlobe.ItemFetching.ItemFetchPickUp;
import Cake.LevelSpecific.SnowGlobe.ItemFetching.ItemFetchPlayerComp;
import Cake.LevelSpecific.SnowGlobe.ItemFetching.ItemDropOffWidget;

event void FPickUpItemReceived();

class AItemFetchDropOffPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp; 

	UPROPERTY(Category = "Setup")
	AItemFetchPickUp Item;

	// UPROPERTY(Category = "Setup")
	// TSubclassOf<UHazeUserWidget> DropOffWidgetClass;

	// UHazeUserWidget Widget;

	FPickUpItemReceived EventItemReceived;

	bool bHaveReceived;

	TPerPlayer<bool> bIsShowingWidget;

	// TPerPlayer<AHazePlayerCharacter> Players;
	
	// TPerPlayer<UItemFetchPlayerComp> PlayerComps;

	TPerPlayer<float> DistanceFromPlayer; 

	float MinItemDistance = 100.f;

	float MinCanDropDistance = 300.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Item.DestinationLoc = ActorLocation;
		Item.DestinationRot = ActorRotation;
		// Item.MinDistance = MinCanDropDistance;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}
}