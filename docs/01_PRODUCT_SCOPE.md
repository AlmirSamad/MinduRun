# Product Scope

## Goal

Build a presentable Flutter MVP for a college project demonstrating social running competition mechanics.

The objective is to demonstrate features and user flow, not production infrastructure.

## Platform goal

The product is designed as a **mobile application**, but during the academic MVP:

- development is primarily executed in Chrome using Flutter Web;
- the presentation is primarily performed on a computer;
- the interface remains mobile-first;
- Android is the secondary target for later validation.

The web presentation is not a separate desktop product.

## Core experience

A user can:

1. enter using a simulated/local profile;
2. create or join a room;
3. create a competition;
4. see participants;
5. register a run;
6. attach/select evidence;
7. enter distance, duration and average pace;
8. receive calculated points;
9. see the activity in the feed;
10. see ranking updates;
11. report inconsistent activities;
12. vote on reported activities;
13. see points removed after rejection.

## MVP data behavior

All application state is local and in memory.

On restart:
- created rooms may disappear;
- submitted activities may disappear;
- ranking may reset;
- demo seed data may reload.

This is expected behavior.

## Non-goals

Do not implement:
- backend;
- API;
- database;
- persistent domain storage;
- cloud auth;
- cloud storage;
- GPS;
- maps;
- route tracking;
- health platform integrations;
- wearables;
- OCR;
- notifications;
- production security infrastructure;
- separate desktop application.

## Terminology

- Room: private friend group.
- Competition: time-bounded challenge inside a room.
- Participant: member of a competition.
- Activity: submitted run.
- Evidence: screenshot/image supporting a run.
- Report: challenge against an activity.
- Vote: validation decision.
- Score: points derived from activity data.
- Ranking: ordered participant scoreboard.
