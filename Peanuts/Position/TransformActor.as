class ATransformActor : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UArrowComponent XArrow;
    default XArrow.SetHiddenInGame(false);
    default XArrow.SetArrowColor(FLinearColor::Red);
    default XArrow.SetbIsEditorOnly(true);
    
    UPROPERTY(DefaultComponent, Attach = XArrow)
    UArrowComponent YArrow;
    default YArrow.SetRelativeRotation(FRotator(0,90,0));
    default YArrow.SetHiddenInGame(false);
    default YArrow.SetArrowColor(FLinearColor::Green);
    default YArrow.SetbIsEditorOnly(true);

    UPROPERTY(DefaultComponent, Attach = XArrow)
    UArrowComponent ZArrow;
    default ZArrow.SetRelativeRotation(FRotator(90,0,0));
    default ZArrow.SetHiddenInGame(false);
    default ZArrow.SetArrowColor(FLinearColor::Blue);
    default ZArrow.SetbIsEditorOnly(true);

    default SetActorHiddenInGame(true);
}