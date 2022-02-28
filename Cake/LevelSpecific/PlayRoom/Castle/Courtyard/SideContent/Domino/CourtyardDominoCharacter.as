import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.Domino.CourtyardDomino;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.ToyCivilians.CourtyardToyCivilian;
event void FOnHitByDomino();

class ACourtyardDominoCharacter : ACourtyardToyCivilian
{
	UPROPERTY(DefaultComponent)
	USphereComponent SphereComp;

	UPROPERTY()
	FOnHitByDomino OnHitByDomino;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent DominoCharAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DominoCharacterIdleAudioEvent;

	UPROPERTY()
	TArray<ACourtyardDomino> Dominoes;

	UPROPERTY()
	UCastleCourtyardVOBank VOBank;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SphereComp.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		DominoCharAkComp.HazePostEvent(DominoCharacterIdleAudioEvent);
	}

	UFUNCTION()
	void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		ACourtyardDomino Domino = Cast<ACourtyardDomino>(OtherActor);
		if (Domino == nullptr)
			return;

		SphereComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
 		OnHitByDomino.Broadcast();
		
		if (VOBank == nullptr)
			return;

		for (ACourtyardDomino ThisDomino : Dominoes)
		{
			if (ThisDomino.PushPlayer == nullptr)
				continue;
			
			FName EventName = ThisDomino.PushPlayer.IsMay() ? n"FoghornDBPlayroomCastleDominoesFallMay" : n"FoghornDBPlayroomCastleDominoesFallCody";
			PlayFoghornVOBankEvent(VOBank, EventName);

			break;
		}
	}
}