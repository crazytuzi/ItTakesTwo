import Peanuts.Triggers.PlayerTrigger;
import Cake.LevelSpecific.Shed.Vacuum.VacuumHoseActor;
import Cake.LevelSpecific.Shed.Vacuum.GoingThroughVacuumCapability;
import Cake.LevelSpecific.Shed.Vacuum.VacuumPointOfInterestActor;

class AVacuumPointOfInterestTrigger : APlayerTrigger
{
	UPROPERTY()
    AVacuumHoseActor Hose;

	UPROPERTY()
	AVacuumPointOfInterestActor PoiActor;

	UPROPERTY()
	float BlendTime = 2.f;

	UPROPERTY()
	float Duration = -1.f;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        OnPlayerEnter.AddUFunction(this, n"ApplyPointOfInterest");
		Super::BeginPlay();
    }

    UFUNCTION()
    void ApplyPointOfInterest(AHazePlayerCharacter Player)
    {
        if (Player.IsAnyCapabilityActive(UGoingThroughVacuumCapability::StaticClass()) && Hose != nullptr && bEnabled)
        {
			FHazePointOfInterest PoISettings;
			if (PoiActor != nullptr)
			{
				PoISettings.FocusTarget.Actor = PoiActor;
				PoISettings.FocusTarget.Component = PoiActor.Direction;
			}
			PoISettings.bMatchFocusDirection = true;
			PoISettings.Duration = Duration;
			PoISettings.Blend = BlendTime;
            Hose.ReapplyPointOfInterest(Player, PoISettings);
        }
    }

    UFUNCTION()
    void EnableTrigger()
    {
        bEnabled = true;
    }

    UFUNCTION()
    void DisableTrigger()
    {
        bEnabled = false;
    }
}