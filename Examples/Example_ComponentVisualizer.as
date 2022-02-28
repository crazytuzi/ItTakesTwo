class UExampleComponentVisualizer : UHazeScriptComponentVisualizer
{
    /* To visualize a component class in editor, create a child class of UHazeScriptComponentVisualizer 
     * with a specified VisualizedClass. This will visualize all components that is or ingerits from that 
     * class, unless there is a specified visualizer for the subclass. 
     * Both code and script classes can be visualized. */
    default VisualizedClass = UExampleVisualizedComponent::StaticClass();

    /* This function will be called every editor tick for each component of the selected actor that inherits 
     * from the visualized class. */
    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UExampleVisualizedComponent Comp = Cast<UExampleVisualizedComponent>(Component);
        if (Comp == nullptr)
            return;

        /* Below are some examples of functions that can be used to visualize components. 
         * Ask a programmer to add more in UHazeScriptComponentVisualizer when needed. */ 
        FVector Loc = Comp.GetOwner().GetActorLocation();
        FRotator Rot = Comp.GetOwner().GetActorRotation();
        FVector Dir = Comp.GetOwner().GetActorForwardVector();
        FVector Up = Comp.GetOwner().GetActorUpVector();
        FLinearColor Color = FLinearColor::MakeRandomColor();

        DrawPoint(Loc, Color, 40.f);
        DrawLine(Loc, Loc + Comp.LineEnd, Color, 3.f);
        DrawDashedLine(Loc, Loc + Comp.DashedLineEnd, Color, 5.f);
        DrawArc(Loc, 60.f, 200.f, Dir, Color, 2.f, Up, 12, 50.f);
        DrawCircle(Loc + Comp.CircleOffset, 70.f, Color, 4.f, Up);
        DrawWireStar(Loc + Comp.StarOffset, 50.f, Color);
        DrawWireDiamond(Loc + Comp.DiamondOffset, Rot, 100.f, Color);
        DrawCoordinateSystem(Loc + Comp.CoordOffset, Rot, 150.f, 10.f);
        DrawWireCapsule(Loc, Rot, Color, 35.f, 86.f, 16, 0.f);
    }
}

class UExampleVisualizedComponent : UActorComponent
{
    UPROPERTY()
    FVector LineEnd = FVector(0,0,500); 

    UPROPERTY()
    FVector DashedLineEnd = FVector(100,100,300); 

    FVector CircleOffset = FVector(0,0,50);
    FVector StarOffset = FVector(-100,100,150);
    FVector DiamondOffset = FVector(-100,-100,200);
    FVector CoordOffset = FVector(100,-100,250);
    FVector ArrowOffset = CoordOffset;
}

class UExampleVizualizedActor : AActor
{
   	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Billboard;
	default Billboard.SetHiddenInGame(false);

    UPROPERTY(DefaultComponent)
    UExampleVisualizedComponent ExampleComp;
}

