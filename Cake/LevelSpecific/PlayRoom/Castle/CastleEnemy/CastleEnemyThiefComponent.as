import Peanuts.Spline.SplineActor;
import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleElevatorSwitchPickupable;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleElevator;

class UCastleEnemyThiefComponent : UActorComponent
{
	UPROPERTY()
	ASplineActor ReturnSpline;

	UPROPERTY()
	ACastleElevatorSwitchPickupable GearToChase;

	UPROPERTY()
	ACastleElevator DestinationElevator;

	ACastleEnemy OwningThief;

	float RecoverRange = 150.f;
	float ReturnRange = 100.f;

	UPROPERTY()
	float WaitTimeBeforeStartingRecovery = 4.f;

	bool bGearStolen = false;
	bool bInsideRecoverRange = false;
	bool bGearRecovered = false;
	bool bGearReturned = false;

	float MoveSpeedCarry = 150.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OwningThief = Cast<ACastleEnemy>(Owner);

		OwningThief.OnKilled.AddUFunction(this, n"OnEnemyKilled");
		GearToChase.OnPickedUpEvent.AddUFunction(this, n"OnPickedUp");

		OwningThief.SetControlSide(Game::GetMay());
	}

	UFUNCTION()
	void OnEnemyKilled(ACastleEnemy Enemy, bool bKilledByDamage)
	{
		GearToChase.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		GearToChase.InteractionComponent.Enable(n"ThiefStolePickup");		
	}

	UFUNCTION()
	void OnPickedUp(AHazePlayerCharacter PlayerCharacter, APickupActor PickupActor)
	{
		bGearStolen = true;
	}

	UFUNCTION()
	void SetThiefStealthed(bool bStealthed)
	{
		if (bStealthed)
		{
			OwningThief.SetActorHiddenInGame(true);
			OwningThief.bUnhittable = true;
		}
		else
		{	
			OwningThief.SetActorHiddenInGame(false);
			OwningThief.bUnhittable = false;
		}
	}
}