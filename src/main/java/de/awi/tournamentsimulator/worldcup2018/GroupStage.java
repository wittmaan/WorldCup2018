package de.awi.tournamentsimulator.worldcup2018;

public class GroupStage {
    Integer points;
    Integer standing;

    public GroupStage(final Integer points) {
        this.points = points;
    }

    @Override
    public String toString() {
        return "GroupStage{" +
                "points=" + points +
                ", standing=" + standing +
                '}';
    }
}
