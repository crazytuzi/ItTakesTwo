const FLinearColor VisualizeWithTagColor(1.f, 0.f, 1.f, 1.f);
const FLinearColor VisualizeNotTagColor(1.f, 0.f, 0.f, 1.f);

class UVisualizeComponentTags
{
    UFUNCTION()
    bool VisualizeLedgeGrabbable(UObject Object, FLinearColor& OutColor) const
    {
        return VisualizeTag(Object, OutColor, n"LedgeGrabbable");
    }

    UFUNCTION()
    bool VisualizeNotLedgeGrabbable(UObject Object, FLinearColor& OutColor) const
    {
        return VisualizeNotTag(Object, OutColor, n"LedgeGrabbable");
    }

    UFUNCTION()
    bool VisualizePiercable(UObject Object, FLinearColor& OutColor) const
    {
        return VisualizeTag(Object, OutColor, n"Piercable");
    }

    UFUNCTION()
    bool VisualizeAlwaysBlockCamera(UObject Object, FLinearColor& OutColor) const
    {
        return VisualizeTag(Object, OutColor, n"AlwaysBlockCamera");
    }

    bool VisualizeTag(UObject Object, FLinearColor& OutColor, FName Tag) const
    {
        UActorComponent Component = Cast<UActorComponent>(Object);
        if (Component == nullptr)
            return false;
        if (!Component.HasTag(Tag))
            return false;

        OutColor = VisualizeWithTagColor;
        return true;
    }

    bool VisualizeNotTag(UObject Object, FLinearColor& OutColor, FName Tag) const
    {
        UActorComponent Component = Cast<UActorComponent>(Object);
        if (Component == nullptr)
            return false;
        if (Component.HasTag(Tag))
            return false;

        OutColor = VisualizeNotTagColor;
        return true;
    }
};