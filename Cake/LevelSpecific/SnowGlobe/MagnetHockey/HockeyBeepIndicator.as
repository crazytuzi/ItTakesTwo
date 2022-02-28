event void FTimerComplete();

enum EBeepIndicatorState
{
	Inactive,
	MoveDown,
	BeepTime,
	MoveUp
}

class AHockeyBeepIndicator : AHazeActor
{
	FTimerComplete OnTimerCompleteEvent;

	EBeepIndicatorState BeepIndicatorState;

	bool bIsTimedWithCountdown;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BeepMesh;
	default BeepMesh.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet CapabilitySheet;

	UPROPERTY(Category = "Setup")
	UMaterialInstance RedMat;

	UPROPERTY(Category = "Setup")
	UMaterialInstance YellowMat;

	UPROPERTY(Category = "Setup")
	UMaterialInstance GreenMat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapabilitySheet(CapabilitySheet);
		BeepMesh.SetMaterial(0, RedMat);
	}

	UFUNCTION()
	void SetRed()
	{
		BeepMesh.SetMaterial(0, RedMat);
	}
}

