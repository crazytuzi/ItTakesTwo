
class UDisableComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UHazeDisableComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		UHazeDisableComponent DisableComp = Cast<UHazeDisableComponent>(Component);
		if (DisableComp != nullptr && DisableComp.bAutoDisable && (
				Editor::IsComponentSelected(DisableComp) || 
				DisableComp.Owner.ActorHasTag(n"GroupedDisable")))
		{
			float Range = DisableComp.AutoDisableRange;

			FVector Origin = DisableComp.Owner.ActorLocation;

			FVector PrevPoint;
			FVector FirstPoint;

			for (int i = 0; i < 40; ++i)
			{
				float Angle = (360.f / 40.f) * float(i);
				FVector Point = Origin + FRotator(0.f, Angle, 0.f).RotateVector(FVector(Range, 0.f, 0.f));
				DrawLine(Origin, Point, FLinearColor::Green, Thickness = 10.f);

				if (i != 0)
					DrawLine(PrevPoint, Point, FLinearColor::Green, Thickness = 10.f);
				else
					FirstPoint = Point;
				PrevPoint = Point;
			}

			DrawLine(PrevPoint, FirstPoint, FLinearColor::Green, Thickness = 10.f);

			for (auto GroupActor : DisableComp.DisableLinkedActors)
			{
				if (GroupActor != nullptr)
					DrawLine(Origin, GroupActor.ActorLocation, FLinearColor::Purple, Thickness = 20.f);
			}
		}
	}
};