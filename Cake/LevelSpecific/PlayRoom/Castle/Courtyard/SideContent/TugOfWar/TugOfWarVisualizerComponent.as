import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.TugOfWar.TugOfWarManagerComponent;

class UTugOfWarVisualizerComponent : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTugOfWarManagerComponent::StaticClass();

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		UTugOfWarManagerComponent Comp = Cast<UTugOfWarManagerComponent>(Component);

		if(Comp == nullptr)
			return;

		DrawInteractionPoints(Comp);
	}

	void DrawInteractionPoints(UTugOfWarManagerComponent Comp)
	{
		FVector Location = Comp.LeftAttach.WorldLocation;
		float Distance = Comp.StepDistance;

		FVector DistanceVector = Comp.LeftAttach.ForwardVector * Distance;

		DrawWireSphere(Location, Color = FLinearColor::Green);

		Location -= DistanceVector;
		DrawWireSphere(Location, Color = FLinearColor::Yellow);

		Location -= DistanceVector;
		DrawWireSphere(Location, Color = FLinearColor::Red);

		Location += DistanceVector * 3;
		DrawWireSphere(Location, Color = FLinearColor::Yellow);

		Location += DistanceVector;
		DrawWireSphere(Location, Color = FLinearColor::Red);

		Location = Comp.RightAttach.WorldLocation;

		DrawWireSphere(Location, Color = FLinearColor::Green);

		Location -= DistanceVector;
		DrawWireSphere(Location, Color = FLinearColor::Yellow);

		Location -= DistanceVector;
		DrawWireSphere(Location, Color = FLinearColor::Red);

		Location += DistanceVector * 3;

		DrawWireSphere(Location, Color = FLinearColor::Yellow);

		Location += DistanceVector;

		DrawWireSphere(Location, Color = FLinearColor::Red);

	}
}