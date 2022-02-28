import Cake.LevelSpecific.PlayRoom.GoldBerg.HeadButtingDino;
import Vino.ActivationPoint.ActivationPointStatics;
class UHeadbuttingDinoActivationPoint : UHazeActivationPoint
{
	default ValidationIdentifier = EHazeActivationPointIdentifierType::LevelSpecific;
	default WidgetClass = Asset("/Game/Blueprints/LevelSpecific/PlayRoom/Goldberg/Dinoland/SlamDino/WBP_DinoSlamWidget.WBP_DinoSlamWidget_C");

	default InitializeDistance(EHazeActivationPointDistanceType::Visible, 2000.f);
	
	/* This is the distance where the second level of the points gui should show up.
	 * At this distance, this the point starts evaulating if it can be targeted nor not.
	*/
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, 200.f);
	
	/* This is the distance where the third level of the points gui should show up.
	 * At this distance, the point can be activated.
	*/
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 200.f);

	AHeadButtingDino Dino;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Dino = Cast<AHeadButtingDino>(Gameplay::GetActorOfClass(AHeadButtingDino::StaticClass()));
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupWidgetVisibility(AHazePlayerCharacter Player, FHazeQueriedActivationPointWithWidgetInformation Query) const
	{	
		if (!Dino.CanSlam)
		{
			return EHazeActivationPointStatusType::Invalid;
		}
		return EHazeActivationPointStatusType::Valid;
	}
}