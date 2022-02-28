event void FDeactivateTheHellTower();

// AHellTowerDeactivationTrigger GetHellTowerDeactivationTrigger()
// {
// 	TArray<AHellTowerDeactivationTrigger> HellTowerDeactivationArray;
// 	GetAllActorsOfClass(HellTowerDeactivationArray);

// 	return HellTowerDeactivationArray[0];
// }

class AHellTowerDeactivationTrigger : AHazeActor
{
	UPROPERTY()
	FDeactivateTheHellTower OnDeactivateTheHellTower;

	UFUNCTION()
	void DeactivateTheHellTower()
	{
		OnDeactivateTheHellTower.Broadcast();
		Print("DeactivateTheHellTower BROADCAST");
	}

	// UFUNCTION(BlueprintOverride)
	// void BeginPlay()
	// {
	// 	if (!HasControl())
	// 		return;
		
	// 	BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
	// 	BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");
	// }

    // UFUNCTION()
    // void TriggeredOnBeginOverlap(
    //     UPrimitiveComponent OverlappedComponent, AActor OtherActor,
    //     UPrimitiveComponent OtherComponent, int OtherBodyIndex,
    //     bool bFromSweep, const FHitResult&in Hit)
    // {
	// 	if (!HasControl())
	// 		return;
			
	// 	AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

	// 	if (Player == Game::May)
	// 		Players[0] = Player;
	// 	else
	// 		Players[1] = Player;
    // }

	// UFUNCTION()
    // void TriggeredOnEndOverlap(
    //     UPrimitiveComponent OverlappedComponent, AActor OtherActor,
    //     UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    // {
	// 	if (!HasControl())
	// 		return;
			
	// 	AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

	// 	if (Player == Game::May)
	// 		Players[0] = Player;
	// 	else
	// 		Players[1] = Player;
    // }
}