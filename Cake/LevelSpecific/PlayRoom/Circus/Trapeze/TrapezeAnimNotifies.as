// They're all used by trapeze interactions in circus level

UCLASS(NotBlueprintable, meta = ("Trapeze Marble Catch (time marker)"))
class UAnimNotify_TrapezeMarbleCatch : UAnimNotify
{
    UFUNCTION(BlueprintOverride)
    FString GetNotifyName() const
    {
        return "Trapeze Marble Catch (time marker)";
    }
}

UCLASS(NotBlueprintable, meta = ("Trapeze Marble Caught (time marker)"))
class UAnimNotify_TrapezeMarbleCaught : UAnimNotify
{
    UFUNCTION(BlueprintOverride)
    FString GetNotifyName() const
    {
        return "Trapeze Marble Caught (time marker)";
    }
}

UCLASS(NotBlueprintable, meta = ("Trapeze Marble Throw (time marker)"))
class UAnimNotify_TrapezeMarbleThrow : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Trapeze Marble Throw (time marker)";
	}
}

UCLASS(NotBlueprintable, meta = ("Trapeze Mount (time marker)"))
class UAnimNotify_TrapezeMount : UAnimNotify
{
    UFUNCTION(BlueprintOverride)
    FString GetNotifyName() const
    {
        return "Trapeze Mount (time marker)";
    }
}

UCLASS(NotBlueprintable, meta = ("Trapeze Unmount (time marker)"))
class UAnimNotify_TrapezeUnmount : UAnimNotify
{
    UFUNCTION(BlueprintOverride)
    FString GetNotifyName() const
    {
        return "Trapeze Unmount (time marker)";
    }
}