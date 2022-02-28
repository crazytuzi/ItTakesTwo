
enum ETagFloorDropOffState
{
	Still,
	DropDown,
	RiseUp
};

class ATagFloorDropOff : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshCompBase;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshCompTop;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshCompTop2;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshCompMini;

	UPROPERTY(Category = "Capability")
	TSubclassOf<UHazeCapability> MainCapability;

	ETagFloorDropOffState TagFloorDropOffState;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(MainCapability);
	}
} 