import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.PlayerTimeSequenceComponent;


class ATimeControlablePlatformAndWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.f;

	UPROPERTY(EditDefaultsOnly, EditConst)
	UHazeLazyPlayerOverlapComponent TutorialZone;

	UPROPERTY(EditDefaultsOnly, EditConst)
	UHazeLazyPlayerOverlapComponent TutorialZoneHead;


	UPROPERTY(Category = "Default", BlueprintReadWrite)
	bool bValidateCloneInZone = false;

	UPROPERTY(Category = "Default", BlueprintReadOnly)
	bool bCloneIsInZone = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bValidateCloneInZone)
		{
			auto Player = Game::GetMay();
			auto CloneComp = UTimeControlSequenceComponent::Get(Player);
			auto Clone = CloneComp.GetClone();
			const float DistanceToClone = Clone.GetActorLocation().DistSquared(TutorialZone.GetWorldLocation());

			const bool bCloneIsOverlapping = DistanceToClone < FMath::Square(5000.f) 
				&& Trace::ComponentOverlapComponent(
				Player.CapsuleComponent,
				TutorialZone,
				TutorialZone.WorldLocation,
				TutorialZone.ComponentQuat,
				bTraceComplex = false
			);

			if (!bCloneIsInZone && bCloneIsOverlapping)
			{
				bCloneIsInZone = true;
				CloneEnteredTutorialZone();
			}
			else if (bCloneIsInZone && !bCloneIsOverlapping)
			{
				bCloneIsInZone = false;
				CloneLeftTutorialZone();
			}
		}

	}

	UFUNCTION(BlueprintEvent)
	void CloneEnteredTutorialZone()
	{
		Log("Blueprint did not override this event.");
	}

	
	UFUNCTION(BlueprintEvent)
	void CloneLeftTutorialZone()
	{
		Log("Blueprint did not override this event.");
	}
}